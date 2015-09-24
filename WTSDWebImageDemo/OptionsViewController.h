//
//  OptionsViewController.h
//  VCTransitions
//
//  Created by Tyler Tillage on 7/3/13.
//  Copyright (c) 2013 CapTech. All rights reserved.
//

#import <UIKit/UIKit.h>

#define USER_DEFAULTS_GENERAL_ENABLED @"GeneralEnabled"
#define USER_DEFAULTS_BLOCK_ENABLED @"BlockEnabled"
#define USER_DEFAULTS_PLACEHOLDER_ENABLED @"PlaceHolderEnabled"

@interface OptionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *contentView;

-(IBAction)dismissModal:(id)sender;

@end
