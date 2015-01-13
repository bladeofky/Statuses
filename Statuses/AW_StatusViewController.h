//
//  AW_StatusViewController.h
//  Statuses
//
//  Created by Alan Wang on 1/6/15.
//  Copyright (c) 2015 Alan Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface AW_StatusViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) NSArray *connectedDevices; // This is an array because the list of devices to choose from will be a set so there will be no duplicates

@property (nonatomic, strong) CBUUID *statusServiceUUID;

@property (nonatomic) BOOL isReadyToAdvertise;
@property (nonatomic) BOOL isReadyToScan;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *statusTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end
