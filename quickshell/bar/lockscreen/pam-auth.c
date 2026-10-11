// pam-auth.c — tiny PAM authentication helper for the Quickshell lock screen
// reads one line (the password) from stdin, exits 0 on success.
#include <security/pam_appl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pwd.h>
#include <unistd.h>

static int conv(int num_msg, const struct pam_message **msgm,
                struct pam_response **response, void *appdata_ptr) {
    const char *password = (const char *)appdata_ptr;
    struct pam_response *reply = calloc((size_t)num_msg, sizeof(struct pam_response));
    if (!reply) return PAM_BUF_ERR;
    for (int i = 0; i < num_msg; i++) {
        if (msgm[i]->msg_style == PAM_PROMPT_ECHO_OFF ||
            msgm[i]->msg_style == PAM_PROMPT_ECHO_ON) {
            reply[i].resp = strdup(password);
            reply[i].resp_retcode = 0;
        }
    }
    *response = reply;
    return PAM_SUCCESS;
}

int main(void) {
    char buf[512];
    if (!fgets(buf, sizeof(buf), stdin)) return 1;
    buf[strcspn(buf, "\n")] = 0;

    struct passwd *pw = getpwuid(getuid());
    if (!pw) return 2;

    pam_handle_t *pamh = NULL;
    struct pam_conv pc = { conv, buf };
    int ret = pam_start("quickshell-lock", pw->pw_name, &pc, &pamh);
    if (ret != PAM_SUCCESS) return 3;

    ret = pam_authenticate(pamh, 0);
    int acct = pam_acct_mgmt(pamh, 0);
    pam_end(pamh, ret);

    return (ret == PAM_SUCCESS && acct == PAM_SUCCESS) ? 0 : 4;
}
