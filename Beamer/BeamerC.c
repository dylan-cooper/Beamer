//
//  BeamerC.c
//  Beamer
//
//  Created by Dylan Cooper on 2018-03-12.
//  Copyright © 2018 Dylan Cooper. All rights reserved.
//

#include "BeamerC.h"
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <syslog.h>
#include <err.h>
#include <string.h>

/*
 * tracks a process and returns when the process exits
 * based on code by Peter Werner (http://doc.geoffgarside.co.uk/kqueue/files/proc.c)
 *
 */
int watch_pid(pid_t pid) {
    int kq, i;
    struct kevent ke;

    kq = kqueue();
    if (kq == -1)
        return 0;
    
    EV_SET(&ke, pid, EVFILT_PROC, EV_ADD,
           NOTE_EXIT, 0, NULL);
    
    /*
     * set the event
     */
    i = kevent(kq, &ke, 1, NULL, 0, NULL);
    if (i == -1)
        return 0;
    
    memset(&ke, 0x00, sizeof(struct kevent));
    
    /*
     * do a blocking kevent call till something happens
     */
    i = kevent(kq, NULL, 0, &ke, 1, NULL);
    if (i == -1)
        return 0;
    return 1;
}

