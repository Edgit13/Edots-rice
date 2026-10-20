use rodio::{Decoder, OutputStream, OutputStreamHandle, Sink};
use std::{
    env, fs,
    io::{BufRead, BufReader, Read, Write},
    os::unix::{net::{UnixListener, UnixStream}, process::CommandExt},
    path::{Path, PathBuf},
    process::{exit, Command, Stdio},
    thread,
    time::Duration,
};

const EXTS: &[&str] = &["mp3", "flac", "wav", "ogg"];

// ---------- paths / config ----------

fn sock_path() -> PathBuf {
    let base = env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into());
    PathBuf::from(base).join("player.sock")
}

fn cfg_path() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| ".".into());
    PathBuf::from(home).join(".config/player/dir")
}

fn load_dir() -> Option<PathBuf> {
    let s = fs::read_to_string(cfg_path()).ok()?;
    let s = s.trim();
    if s.is_empty() { None } else { Some(PathBuf::from(s)) }
}

fn scan(dir: &Path, out: &mut Vec<PathBuf>) {
    if let Ok(rd) = fs::read_dir(dir) {
        for e in rd.flatten() {
            let p = e.path();
            if p.is_dir() {
                scan(&p, out);
            } else if p
                .extension()
                .and_then(|x| x.to_str())
                .map(|x| EXTS.contains(&x.to_lowercase().as_str()))
                .unwrap_or(false)
            {
                out.push(p);
            }
        }
    }
}

fn tracks_from_cfg() -> Vec<PathBuf> {
    let mut v = Vec::new();
    if let Some(d) = load_dir() {
        scan(&d, &mut v);
    }
    v.sort();
    v
}

fn name(p: &Path) -> String {
    p.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default()
}

// ---------- client ----------

fn send(cmd: &str) -> std::io::Result<String> {
    let mut s = UnixStream::connect(sock_path())?;
    s.set_read_timeout(Some(Duration::from_secs(5)))?;
    writeln!(s, "{cmd}")?;
    let mut out = String::new();
    s.read_to_string(&mut out)?;
    Ok(out)
}

fn ensure_daemon() {
    if UnixStream::connect(sock_path()).is_ok() {
        return;
    }
    let exe = env::current_exe().expect("current_exe");
    Command::new(exe)
        .arg("--daemon")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .process_group(0)
        .spawn()
        .expect("failed to spawn daemon");
    for _ in 0..40 {
        if UnixStream::connect(sock_path()).is_ok() {
            return;
        }
        thread::sleep(Duration::from_millis(50));
    }
    eprintln!("daemon failed to start (no audio device?)");
    exit(1);
}

fn usage() -> ! {
    eprintln!(
        "usage:
  player -q list
  player -q next
  player -q stop
  player -q play [n]
  player -q set dir <path>
  player -q quit"
    );
    exit(1);
}

fn main() {
    let mut a: Vec<String> = env::args().skip(1).collect();
    if a.first().map(|s| s == "--daemon").unwrap_or(false) {
        return daemon();
    }
    if a.first().map(|s| s == "-q").unwrap_or(false) {
        a.remove(0);
    }
    if a.is_empty() {
        usage();
    }

    match a[0].as_str() {
        "set" => {
            if a.len() < 3 || a[1] != "dir" {
                usage();
            }
            let p = match fs::canonicalize(a[2..].join(" ")) {
                Ok(p) if p.is_dir() => p,
                _ => {
                    eprintln!("not a directory: {}", a[2..].join(" "));
                    exit(1);
                }
            };
            let cfg = cfg_path();
            fs::create_dir_all(cfg.parent().unwrap()).ok();
            fs::write(&cfg, p.to_string_lossy().as_bytes()).expect("write config");
            let _ = send("reload");
            println!("dir = {}", p.display());
        }
        "play" => {
            ensure_daemon();
            let cmd = if a.len() > 1 { format!("play {}", a[1]) } else { "play".into() };
            print!("{}", send(&cmd).unwrap_or_default());
        }
        "list" => match send("list") {
            Ok(r) => print!("{r}"),
            Err(_) => {
                let t = tracks_from_cfg();
                if t.is_empty() {
                    println!("(empty) use: player -q set dir <path>");
                }
                for (i, p) in t.iter().enumerate() {
                    println!("  {:>3}. {}", i + 1, name(p));
                }
            }
        },
        "next" | "stop" | "quit" => match send(&a[0]) {
            Ok(r) => print!("{r}"),
            Err(_) => println!("not running"),
        },
        _ => usage(),
    }
}

// ---------- daemon ----------

struct State {
    handle: OutputStreamHandle,
    sink: Option<Sink>,
    tracks: Vec<PathBuf>,
    idx: usize,
    playing: bool,
}

impl State {
    fn reload(&mut self) {
        self.stop();
        self.tracks = tracks_from_cfg();
        self.idx = 0;
    }

    fn stop(&mut self) {
        if let Some(s) = self.sink.take() {
            s.stop();
        }
        self.playing = false;
    }

    fn start(&mut self) -> String {
        if self.tracks.is_empty() {
            return "no tracks (use: player -q set dir <path>)".into();
        }
        self.stop();
        let n = self.tracks.len();
        for _ in 0..n {
            let p = self.tracks[self.idx].clone();
            if let Ok(f) = fs::File::open(&p) {
                if let Ok(src) = Decoder::new(BufReader::new(f)) {
                    if let Ok(sink) = Sink::try_new(&self.handle) {
                        sink.append(src);
                        self.sink = Some(sink);
                        self.playing = true;
                        return format!("playing {}. {}", self.idx + 1, name(&p));
                    }
                }
            }
            self.idx = (self.idx + 1) % n;
        }
        "no playable tracks".into()
    }

    fn tick(&mut self) {
        if self.playing && self.sink.as_ref().map(|s| s.empty()).unwrap_or(false) {
            self.idx = (self.idx + 1) % self.tracks.len().max(1);
            self.start();
        }
    }

    /// returns true if the daemon should quit
    fn handle(&mut self, conn: UnixStream) -> bool {
        let _ = conn.set_nonblocking(false);
        let _ = conn.set_read_timeout(Some(Duration::from_secs(1)));
        let mut line = String::new();
        if BufReader::new(&conn).read_line(&mut line).is_err() {
            return false;
        }
        let mut it = line.split_whitespace();
        let cmd = it.next().unwrap_or("");
        let arg = it.next();
        let mut quit = false;

        let resp = match cmd {
            "list" => {
                if self.tracks.is_empty() {
                    "(empty) use: player -q set dir <path>".to_string()
                } else {
                    self.tracks
                        .iter()
                        .enumerate()
                        .map(|(i, p)| {
                            let m = if self.playing && i == self.idx { ">" } else { " " };
                            format!("{m} {:>3}. {}", i + 1, name(p))
                        })
                        .collect::<Vec<_>>()
                        .join("\n")
                }
            }
            "play" => {
                if let Some(n) = arg.and_then(|s| s.parse::<usize>().ok()) {
                    if n >= 1 && n <= self.tracks.len() {
                        self.idx = n - 1;
                        self.start()
                    } else {
                        "index out of range".into()
                    }
                } else if self.playing {
                    "already playing".into()
                } else {
                    self.start()
                }
            }
            "next" => {
                if self.tracks.is_empty() {
                    "no tracks".into()
                } else {
                    self.idx = (self.idx + 1) % self.tracks.len();
                    self.start()
                }
            }
            "stop" => {
                self.stop();
                "stopped".into()
            }
            "reload" => {
                self.reload();
                format!("{} tracks", self.tracks.len())
            }
            "quit" => {
                quit = true;
                "bye".into()
            }
            _ => "unknown command".into(),
        };

        let mut c = &conn;
        let _ = writeln!(c, "{resp}");
        quit
    }
}

fn daemon() {
    let sp = sock_path();
    let _ = fs::remove_file(&sp);
    let listener = UnixListener::bind(&sp).expect("bind socket");
    listener.set_nonblocking(true).expect("nonblocking");

    let (_stream, handle) = OutputStream::try_default().expect("no audio device");
    let mut st = State { handle, sink: None, tracks: Vec::new(), idx: 0, playing: false };
    st.reload();

    loop {
        match listener.accept() {
            Ok((conn, _)) => {
                if st.handle(conn) {
                    break;
                }
            }
            Err(_) => {}
        }
        st.tick();
        thread::sleep(Duration::from_millis(100));
    }
    let _ = fs::remove_file(&sp);
}
