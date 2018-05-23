//
//  MergeDriver.h
//  Jackdaw
//
//  Created by Jonson Goff-White on 17/05/2018.
//  Copyright © 2018 Jonson Goff-White. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <ObjectiveGit/git2/sys/merge.h>

int als_merge_driver_apply_fn(git_merge_driver *self, const char **path_out, uint32_t *mode_out, git_buf *merged_out, const char *filter_name, const git_merge_driver_source *src);

bool check_merge_driver_exists(void);
void init_als_merge_driver(void);
