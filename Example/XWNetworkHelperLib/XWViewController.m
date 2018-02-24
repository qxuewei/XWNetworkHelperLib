//
//  XWViewController.m
//  XWNetworkHelperLib
//
//  Created by qxuewei@yeah.net on 02/24/2018.
//  Copyright (c) 2018 qxuewei@yeah.net. All rights reserved.
//

#import "XWViewController.h"
#import "XWNetworkHelper.h"


@interface XWViewController ()

@end

@implementation XWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *path = @"https://www.baidu.com";
    [XWNetworkHelper setResponseSerializer:XWResponseSerializerHTTP];
    
    
    // get
    [XWNetworkHelper GET:path parameters:nil success:^(id responseObject) {
        //成功
        NSLog(@"成功%@",responseObject);
    } failure:^(NSError *error) {
        //失败
        NSLog(@"失败%@",error);
    }];
    
    [XWNetworkHelper GET:path parameters:nil responseCache:^(id responseObject) {
        //缓存数据
        NSLog(@"缓存数据%@",responseObject);
    } success:^(id responseObject) {
        //成功-请求的数据
        NSLog(@"成功%@",responseObject);
    } failure:^(NSError *error) {
        //失败
        NSLog(@"失败%@",error);
    }];
    
    //post
    [XWNetworkHelper POST:path parameters:nil success:^(id responseObject) {
        //成功
        NSLog(@"成功%@",responseObject);
    } failure:^(NSError *error) {
        //失败
        NSLog(@"失败%@",error);
    }];
    
    [XWNetworkHelper POST:path parameters:nil responseCache:^(id responseObject) {
        //缓存数据
        NSLog(@"缓存数据%@",responseObject);
    } success:^(id responseObject) {
        //成功-请求的数据
        NSLog(@"成功%@",responseObject);
    } failure:^(NSError *error) {
        //失败
        NSLog(@"失败%@",error);
    }];
}

@end
