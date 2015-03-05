//
//  PGRApplication.m
//  PonyRouter
//
//  Created by 崔 明辉 on 15/3/5.
//  Copyright (c) 2015年 多玩事业部 iOS开发组 YY Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "PGRApplication.h"
#import "PGRCore.h"
#import "PGRCore+PGRPrivate.h"
#import "PGRNode.h"

static BOOL swizzled;

@interface PGRApplication ()

@property (nonatomic, strong) PGRCore *core;

@end

@implementation PGRApplication

+ (PGRApplication *)sharedInstance {
    static PGRApplication *application;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        application = [[PGRApplication alloc] init];
    });
    return application;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.core = [[PGRCore alloc] init];
    }
    return self;
}

- (void)setConfigure:(PGRConfiguration *)configure {
    [self.core.configurationManager setConfigure:configure];
}

- (PGRConfiguration *)configure {
    return self.core.configurationManager.configure;
}

- (void)addNode:(PGRNode *)node {
    [self.core.nodeManager addNode:node];
}

- (BOOL)canOpenURL:(NSURL *)URL {
    return [self.core.nodeManager nodeForURL:URL] != nil;
}

- (void)openURL:(NSURL *)URL {
    [self openURL:URL sourceObject:nil];
}

- (void)openURL:(NSURL *)URL sourceObject:(NSObject *)sourceObject {
    PGRNode *node = [self.core.nodeManager nodeForURL:URL];
    if (node == nil) {
        if (!swizzled) {
            [[UIApplication sharedApplication] openURL:URL];
        }
    }
    else {
        node.executingBlock(URL, nil, sourceObject);
    }
}

@end

@implementation PGRApplication (Swizzle)

+ (void)swizzleUIApplicationMethod {
    swizzled = YES;
    Method origMethod = class_getInstanceMethod([UIApplication class],
                                                @selector(openURL:));
    Method replacingMethod = class_getInstanceMethod([PGRApplication class],
                                                     @selector(swizzle_PGRopenURL:));
    method_exchangeImplementations(origMethod, replacingMethod);
}

- (void)swizzle_PGRopenURL:(NSURL *)URL {
    if ([[PGRApplication sharedInstance] canOpenURL:URL]) {
        [[PGRApplication sharedInstance] openURL:URL];
    }
    else {
        [self swizzle_PGRopenURL:URL];
    }
}

@end
