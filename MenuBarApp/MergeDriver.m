//
//  MergeDriver.m
//  MenuBarApp
//
//  Created by Jonson Goff-White on 17/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "MergeDriver.h"

static git_merge_driver als_merge_driver;

int als_merge_driver_apply_fn(git_merge_driver *self, const char **path_out, uint32_t *mode_out, git_buf *merged_out, const char *filter_name, const git_merge_driver_source *src) {
    
    printf("\nrunning apply\n");
    return GIT_PASSTHROUGH;
}

bool check_merge_driver_exists() {
    git_merge_driver *driver = git_merge_driver_lookup("*.als");
    
    return driver != NULL;
}

void init_als_merge_driver() {
    
    printf("begin init als merge driver");
    
    als_merge_driver.version = GIT_MERGE_DRIVER_VERSION;
    als_merge_driver.initialize = NULL;
    als_merge_driver.shutdown = NULL;
    als_merge_driver.apply = *als_merge_driver_apply_fn;
    
    git_merge_driver_register("*.als", &als_merge_driver);
}
