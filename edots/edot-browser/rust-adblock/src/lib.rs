use adblock::engine::Engine;
use adblock::lists::{FilterSet, ParseOptions};
use adblock::request::Request;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_void};
use std::ptr;

pub struct EdotEngine { engine: Engine }

#[no_mangle]
pub unsafe extern "C" fn edot_adblock_create() -> *mut c_void {
    let set = FilterSet::new(false);
    Box::into_raw(Box::new(EdotEngine { engine: Engine::new_with_filter_set(set) })) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn edot_adblock_create_from_text(text: *const c_char) -> *mut c_void {
    if text.is_null() { return ptr::null_mut(); }
    let Ok(text) = CStr::from_ptr(text).to_str() else { return ptr::null_mut(); };
    let mut set = FilterSet::new(false);
    set.add_filter_list(text.to_owned(), ParseOptions::default());
    Box::into_raw(Box::new(EdotEngine { engine: Engine::new_with_filter_set(set) })) as *mut c_void
}

#[no_mangle]
pub unsafe extern "C" fn edot_adblock_check(
    handle: *const c_void,
    url: *const c_char,
    source: *const c_char,
    request_type: *const c_char,
) -> bool {
    if handle.is_null() || url.is_null() || source.is_null() || request_type.is_null() { return false; }
    let engine = &*(handle as *const EdotEngine);
    let Ok(url) = CStr::from_ptr(url).to_str() else { return false; };
    let Ok(source) = CStr::from_ptr(source).to_str() else { return false; };
    let Ok(request_type) = CStr::from_ptr(request_type).to_str() else { return false; };
    let Ok(req) = Request::new(url, source, request_type, "get") else { return false; };
    engine.engine.check_network_request(&req).should_block()
}

#[no_mangle]
pub unsafe extern "C" fn edot_adblock_free(handle: *mut c_void) {
    if !handle.is_null() { drop(Box::from_raw(handle as *mut EdotEngine)); }
}
