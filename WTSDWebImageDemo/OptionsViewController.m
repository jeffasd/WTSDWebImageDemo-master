//
//  OptionsViewController.m
//  VCTransitions
//
//  Created by Tyler Tillage on 7/3/13.
//  Copyright (c) 2013 CapTech. All rights reserved.
//

#import "OptionsViewController.h"

@interface OptionsViewController () {
    NSArray *_sectionTitles, *_cellTitles, *_cellActions;
    UISwitch *_generalSwitch, *_blockSwitch, *_placeHolderSwitch;
}

@end

@implementation OptionsViewController

static NSString *CellIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    // 启用基础
    _generalSwitch = [[UISwitch alloc] init];
    [_generalSwitch addTarget:self action:@selector(generalSwitchWasChanged) forControlEvents:UIControlEventValueChanged];
    
    // 带block回调
    _blockSwitch = [[UISwitch alloc] init];
    [_blockSwitch addTarget:self action:@selector(blockSwitchWasChanged) forControlEvents:UIControlEventValueChanged];
    
    // 带占位图片
    _placeHolderSwitch = [[UISwitch alloc] init];
    [_placeHolderSwitch addTarget:self action:@selector(placeHolderSwitchWasChanged) forControlEvents:UIControlEventValueChanged];
    
    // Modal view styling
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    self.view.layer.shadowOpacity = 0.5;
    self.view.layer.shadowRadius = 10.0;
    self.view.layer.cornerRadius = 3.0;
    self.contentView.layer.cornerRadius = 3.0;
    self.contentView.layer.masksToBounds = YES;
    
    _sectionTitles = @[@"General", @"Other Type"];
    _cellTitles = @[@[@"启用基础图片缓存"], @[@"block", @"添加默认图片"]];
    _cellActions = @[@[@"sd_setImageWithURL"], @[@"sd_setImageWithURL:completed:", @"sd_setImageWithURL:placeholderImage:", @"sd_setImageWithURL:placeholderImage:completed:"]];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Table View Data Source

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_sectionTitles objectAtIndex:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sectionTitles = [_cellTitles objectAtIndex:section];
    return sectionTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [[_cellTitles objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    // 设置switch按钮的初始状态
    if (indexPath.section == 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        if (indexPath.row == 0) {
            _generalSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_GENERAL_ENABLED];
            cell.accessoryView = _generalSwitch;
        }
    } else if (indexPath.section == 1) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        if (indexPath.row == 0) {
            _blockSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_BLOCK_ENABLED];
            cell.accessoryView = _blockSwitch;
        }
        else if (indexPath.row == 1) {
            _placeHolderSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_PLACEHOLDER_ENABLED];
            cell.accessoryView = _placeHolderSwitch;
        }else {
            cell.accessoryType = UITableViewCellAccessoryNone;

        }
    }
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) return @"给图片缓存方法添加设置，包括（带回调block，以及默认占位图片的图片缓存方式）";
    return nil;
}

#pragma mark - Custom Methods

-(IBAction)dismissModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 点击对应switch，设置对应选项

-(void)generalSwitchWasChanged {
    [[NSUserDefaults standardUserDefaults] setBool:_generalSwitch.on forKey:USER_DEFAULTS_GENERAL_ENABLED];
    if(!_generalSwitch.on)
    {
        _placeHolderSwitch.on = false;
        _placeHolderSwitch.enabled = NO;
        [[NSUserDefaults standardUserDefaults] setBool:_placeHolderSwitch.on forKey:USER_DEFAULTS_PLACEHOLDER_ENABLED];
        
        _blockSwitch.on = false;
        _blockSwitch.enabled = NO;
        [[NSUserDefaults standardUserDefaults] setBool:_blockSwitch.on forKey:USER_DEFAULTS_BLOCK_ENABLED];
    }else
    {
        _placeHolderSwitch.enabled = YES;
        _blockSwitch.enabled = YES;
    }
    
}

-(void)blockSwitchWasChanged
{
    [[NSUserDefaults standardUserDefaults] setBool:_blockSwitch.on forKey:USER_DEFAULTS_BLOCK_ENABLED];
}

-(void)placeHolderSwitchWasChanged
{
    [[NSUserDefaults standardUserDefaults] setBool:_placeHolderSwitch.on forKey:USER_DEFAULTS_PLACEHOLDER_ENABLED];
}

@end
