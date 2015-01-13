//
//  AW_ConnectViewController.h
//  Statuses
//
//  Created by Alan Wang on 1/6/15.
//  Copyright (c) 2015 Alan Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class AW_StatusViewController;

@interface AW_ConnectViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSMutableArray *connectedPeripherals; // This needs to be public so that AW_StatusViewController can assgn connected devices to it
@property (nonatomic, weak) AW_StatusViewController *statusVC;

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end
