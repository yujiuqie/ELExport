//
//  ViewController.m
//  ELog
//
//  Created by viktyz on 16/9/21.
//  Copyright © 2016年 AlfredJiang. All rights reserved.
//

#import "ViewController.h"
#import "ELExport.h"

@interface ViewController ()
{
    NSInteger count;
}

@property (weak, nonatomic) IBOutlet UILabel *labelCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickAddButton:(UIButton *)sender {
    
    count++;
    
    self.labelCount.text = [NSString stringWithFormat:@"%ld",count];
    
    ELog(@"%ld;%f",count,[[NSDate date] timeIntervalSince1970]);
}

- (IBAction)clickClearButton:(UIButton *)sender {
    
    [[ELExport sharedExport] clearAllLogs];
}

@end
