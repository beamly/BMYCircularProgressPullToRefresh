//
//  BMYPullToRefreshView.m
//  BMYPullToRefreshDemo
//
//  Created by Alberto De Bortoli on 15/05/2014.
//  Copyright (c) 2014 Beamly. All rights reserved.
//

#import "BMYPullToRefreshView.h"

#import "UIScrollView+BMYPullToRefresh.h"

static CGFloat const kPullToRefreshResetContentInsetAnimationTime = 0.3;
static CGFloat const kPullToRefreshDragToTrigger = 80;

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

@interface BMYPullToRefreshView ()

@property (nonatomic, strong) UIView<BMYProgressViewProtocol> *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign) UIEdgeInsets externalContentInset;
@property (nonatomic, assign, getter = isUpdatingScrollViewContentInset) BOOL updatingScrollViewContentInset;

- (void)_resetFrame;

@end

@implementation BMYPullToRefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithHeight:0.0f scrollView:nil];
}

- (instancetype)initWithHeight:(CGFloat)height scrollView:(UIScrollView *)scrollView {
    NSParameterAssert(height > 0.0f);
    NSParameterAssert(scrollView);
    
    CGRect frame = CGRectMake(0.0f, 0.0f, 0.0f, height);
    if (self = [super initWithFrame:frame]) {
        _scrollView = scrollView;
        _externalContentInset = scrollView.contentInset;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _state = BMYPullToRefreshStateStopped;
        _preserveContentInset = YES;
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = NO;
        [self setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        [self setActivityIndicatorViewColor:[UIColor lightGrayColor]];
        [self addSubview:_activityIndicatorView];
        [self _resetFrame];
    }
    
    return self;
}

- (void)layoutSubviews {
    CGRect viewBounds = [_progressView bounds];
    CGPoint origin = CGPointMake(roundf((CGRectGetWidth(self.bounds) - CGRectGetWidth(viewBounds)) / 2), roundf(( CGRectGetHeight(self.bounds) - CGRectGetHeight(viewBounds)) / 2));
    [_progressView setFrame:CGRectMake(origin.x, origin.y, CGRectGetWidth(viewBounds), CGRectGetHeight(viewBounds))];
    [_activityIndicatorView setFrame:CGRectMake(origin.x, origin.y, CGRectGetWidth(viewBounds), CGRectGetHeight(viewBounds))];
}

#pragma mark - Public Methods

- (void)startAnimating {
    self.state = BMYPullToRefreshStateTriggered;
    
    if (fequalzero(_scrollView.contentOffset.y)) {
        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x, -CGRectGetHeight(self.frame)) animated:YES];
    }
    
    self.state = BMYPullToRefreshStateLoading;
}

- (void)stopAnimating {
    if (_state != BMYPullToRefreshStateStopped) {
        self.state = BMYPullToRefreshStateStopped;
        CGPoint originalContentOffset = CGPointMake(-_externalContentInset.left, -_externalContentInset.top);
        [self.scrollView setContentOffset:originalContentOffset animated:YES];
        [self.progressView setProgress:0.0f];
    }
}

- (void)setState:(BMYPullToRefreshState)newState {
    
    if (_state == newState)
        return;
    
    BMYPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case BMYPullToRefreshStateAll:
        case BMYPullToRefreshStateTriggered:
        case BMYPullToRefreshStateStopped: {
            [self _resetScrollViewContentInset];
            break;
        }
            
        case BMYPullToRefreshStateLoading: {
            [self _setScrollViewContentInsetForLoadingAnimated:YES];
            
            if (previousState == BMYPullToRefreshStateTriggered && _pullToRefreshActionHandler) {
                [UIView animateWithDuration:kPullToRefreshResetContentInsetAnimationTime
                                 animations:^{
                                     _progressView.alpha = 0.0f;
                                     _activityIndicatorView.alpha = 1.0f;
                                     [_activityIndicatorView startAnimating];
                                     _pullToRefreshActionHandler(self);
                                 }];
            }
            break;
        }
    }
}

- (void)setProgressView:(UIView<BMYProgressViewProtocol> *)view {
    _activityIndicatorView.hidesWhenStopped = view != nil;
    
    if (_progressView) {
        [_progressView removeFromSuperview];
    }
    
    _progressView = view;
    [self addSubview:_progressView];
    [self setNeedsLayout];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
    else if ([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        [self _resetFrame];
    }
    else if ([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
    else if ([keyPath isEqualToString:@"contentInset"]) {
        if (!_updatingScrollViewContentInset) {
            _externalContentInset = [[change valueForKey:NSKeyValueChangeNewKey] UIEdgeInsetsValue];
            [self _resetFrame];
        }
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (_state == BMYPullToRefreshStateLoading) {
        [self _setScrollViewContentInsetForLoadingAnimated:NO];
    } else {
        CGFloat dragging = -contentOffset.y - _externalContentInset.top;
        if (!self.scrollView.isDragging && _state == BMYPullToRefreshStateTriggered) {
            self.state = BMYPullToRefreshStateLoading;
        }
        else if (dragging >= kPullToRefreshDragToTrigger && self.scrollView.isDragging && self.state == BMYPullToRefreshStateStopped) {
            self.state = BMYPullToRefreshStateTriggered;
        }
        else if (dragging < kPullToRefreshDragToTrigger && self.state != BMYPullToRefreshStateStopped) {
            self.state = BMYPullToRefreshStateStopped;
        }
        
        if (dragging > 0 && _state != BMYPullToRefreshStateLoading) {
            [_progressView setProgress:(dragging * 1 / kPullToRefreshDragToTrigger)];
        }
    }
}

#pragma mark - Accessors Pass Through

- (UIColor *)activityIndicatorViewColor {
    return self.activityIndicatorView.color;
}

- (void)setActivityIndicatorViewColor:(UIColor *)color {
    self.activityIndicatorView.color = color;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return self.activityIndicatorView.activityIndicatorViewStyle;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

- (void)setPreserveContentInset:(BOOL)preserveContentInset{
    if (_preserveContentInset != preserveContentInset) {
        _preserveContentInset = preserveContentInset;

        if (self.bounds.size.height > 0.0f) {
            [self _resetFrame];
        }
    }
}
#pragma mark - Scroll View

- (void)_resetScrollViewContentInset {
    [UIView animateWithDuration:kPullToRefreshResetContentInsetAnimationTime
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         [self _setScrollViewContentInset:_externalContentInset];
                     }
                     completion:^(BOOL finished) {
                         if (_progressView) {
                             _progressView.alpha = 1.0f;
                             _activityIndicatorView.alpha = 0.0f;
                         }
                         [_activityIndicatorView stopAnimating];
                     }];
}

- (void)_setScrollViewContentInsetForLoadingAnimated:(BOOL)animated {
    UIEdgeInsets loadingInset = _externalContentInset;
    loadingInset.top += CGRectGetHeight(self.bounds);
    void (^updateBlock)(void) = ^{
        [self _setScrollViewContentInset:loadingInset];
    };
    if (animated) {
        [UIView animateWithDuration:kPullToRefreshResetContentInsetAnimationTime
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:updateBlock
                         completion:nil];
    }
    else {
        updateBlock();
    }
}

- (void)_setScrollViewContentInset:(UIEdgeInsets)contentInset {
    BOOL alreadyUpdating = _updatingScrollViewContentInset; // Check to prevent errors from recursive calls.
    if (!alreadyUpdating) {
        self.updatingScrollViewContentInset = YES;
    }
    self.scrollView.contentInset = contentInset;
    if (!alreadyUpdating) {
        self.updatingScrollViewContentInset = NO;
    }
}

#pragma mark - Utilities

- (void)_resetFrame {
    CGFloat height = CGRectGetHeight(self.bounds);
    
    if (_preserveContentInset) {
        self.frame = CGRectMake(0.0f,
                                -height -_externalContentInset.top,
                                CGRectGetWidth(_scrollView.bounds),
                                height);
    }
    else {
        self.frame = CGRectMake(-_externalContentInset.left,
                                -height,
                                CGRectGetWidth(_scrollView.bounds),
                                height);
    }
}

@end
