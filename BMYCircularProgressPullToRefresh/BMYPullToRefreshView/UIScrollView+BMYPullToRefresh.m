//
//  UIScrollView+BMYPullToRefresh.h
//  BMYPullToRefreshDemo
//
//  Created by Alberto De Bortoli on 15/05/2014.
//  Copyright (c) 2014 Beamly. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "UIScrollView+BMYPullToRefresh.h"

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (BMYPullToRefresh)

@dynamic pullToRefreshView;

#pragma mark - Public Methods

- (void)setPullToRefreshWithHeight:(CGFloat)height
                     actionHandler:(void (^)(BMYPullToRefreshView *pullToRefreshView))actionHandler {
    [self tearDownPullToRefresh];
    BMYPullToRefreshView *view = [[BMYPullToRefreshView alloc] initWithHeight:height scrollView:self];
    [self addSubview:view];
    self.pullToRefreshView = view;
    [self _setupPullToRefresh];
    self.pullToRefreshView.pullToRefreshActionHandler = actionHandler;
}

- (void)tearDownPullToRefresh {
    if (self.pullToRefreshView) {
        [self _tearDownPullToRefresh];
        [self.pullToRefreshView removeFromSuperview];
        self.pullToRefreshView = nil;
    }
}

#pragma mark - Dynamic Accessors

- (BMYPullToRefreshView *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setPullToRefreshView:(BMYPullToRefreshView *)pullToRefreshView {
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private Methods

- (void)_tearDownPullToRefresh {
    [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
    [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
    [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
    [self removeObserver:self.pullToRefreshView forKeyPath:@"contentInset"];
}

- (void)_setupPullToRefresh {
    [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self.pullToRefreshView forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
}

@end
