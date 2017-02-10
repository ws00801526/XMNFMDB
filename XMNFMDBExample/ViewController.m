//
//  ViewController.m
//  XMNFMDBExample
//
//  Created by XMFraker on 16/12/21.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "ViewController.h"

#import "XMNTeacher.h"

#import <XMNFMDB/XMNFMDB.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *conditionTextField;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [NSFileManager xmn_directoryPathForDocuments:@"测试路径"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)insertAction:(UIButton *)sender {
    
}

- (IBAction)deleteAction:(UIButton *)sender {
    
}

- (IBAction)queryAction:(UIButton *)sender {

    NSString *result = self.resultTextView.text;
    
    [result stringByAppendingFormat:@"\nQuery Objects Start"];
    NSArray *students = [XMNStudent xmn_objectsWithWhereCondition:self.conditionTextField.text];
    result = [result stringByAppendingFormat:@"\n query Objects count :%ld  \n for condition : %@",students.count , self.conditionTextField.text];
    [result stringByAppendingFormat:@"\nQuery Objects End"];
    self.resultTextView.text = result;
}

- (IBAction)insertHugeAction:(UIButton *)sender {
    
    XMNLogSetLoggerLevel(XMNLogLevelWarning);
    XMNTick
    NSMutableArray *students = [NSMutableArray array];
    for (int i = 0; i < 10000; i ++) {
        XMNStudent *student = [[XMNStudent alloc] init];
        student.name = [NSString stringWithFormat:@"student_%05d",i];
        student.age = arc4random() % 100 + 5;
        [students addObject:student];
    }
    BOOL success = [[XMNStudent xmn_usingDBHelper] insertObjects:students];
    XMNTock
    XMNLogSetLoggerLevel(XMNLogLevelInfo);
}

@end
