/*
 MVCustomAlertView.m
 Copyright (c) 2014 Andrea Bizzotto bizz84@gmail.com

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import "MVCustomAlertView.h"
#import <Masonry/Masonry.h>
#import <MVModalTransitions/MVPopupTransition.h>

static CGFloat kLabelHeight = 44.0f;
static CGFloat kPickerHeight = 162.0f;
static CGFloat kButtonsHeight = 44.0f;

@interface MVCustomAlertView ()<UIViewControllerTransitioningDelegate>
@property (strong) UILabel *titleLabel;
@property (strong) UIButton *cancelButton;
@property (strong) UIButton *confirmButton;
@property (weak) id<MVCustomAlertViewClientDelegate> delegate;
@property(strong, nonatomic) MVPopupTransition *animator;
@end

@implementation MVCustomAlertView


- (id)initWithDelegate:(id<MVCustomAlertViewClientDelegate>)delegate {

    if ((self = [super init])) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
        self.delegate = delegate;
        self.animator = [MVPopupTransition createWithSize:[self modalSize] dimBackground:YES shouldDismissOnBackgroundViewTap:NO delegate:nil];
    }
    return self;
}

- (void)loadView {

    self.view = [UIView new];
    self.view.backgroundColor = [UIColor whiteColor];

    // TODO: Styling
    self.titleLabel = [UILabel new];
    self.cancelButton = [UIButton new];
    self.confirmButton = [UIButton new];

    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];

    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.text = self.title;

    UIView *contentView = [self contentView];

    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.confirmButton addTarget:self action:@selector(confirmButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.titleLabel];
    [self.view addSubview:contentView];
    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.confirmButton];

    [self.titleLabel makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.equalTo(@(kLabelHeight));
        make.top.equalTo(self.view);
    }];
    [contentView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.bottom);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.cancelButton.top);
    }];
    [self.cancelButton makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view.centerX);
        make.height.equalTo(@(kButtonsHeight));
        make.bottom.equalTo(self.view);
    }];
    [self.confirmButton makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.centerX);
        make.right.equalTo(self.view.right);
        make.height.equalTo(@(kButtonsHeight));
        make.bottom.equalTo(self.view);
    }];

    // Somehow needed to prevent content from going outside bounds
    self.view.clipsToBounds = YES;
}

- (CGSize)modalSize
{
    float requiredHeight = kLabelHeight + kPickerHeight + kButtonsHeight + 50;
    return CGSizeMake(300, requiredHeight);
}

- (void)cancelButtonPressed {

    [self dismissViewControllerAnimated:YES completion:^{

        if ([self.delegate respondsToSelector:@selector(customAlertViewDidCancel:)]) {
            [self.delegate customAlertViewDidCancel:self];
        }
    }];
}

- (void)confirmButtonPressed {

    // Either use standard protocol
    if ([self.delegate respondsToSelector:@selector(customAlertViewDidConfirm:)]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate customAlertViewDidConfirm:self];
        }];
    }
    // or let subclass handle this
    else {
        if ([self onConfirm]) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - SUCustomAlertViewDelegate

- (UIView *)contentView {
    NSAssert(NO, @"%s must be implemented by subclasses", __func__);
    return nil;
}


- (BOOL)onConfirm {

    return YES;
}

- (void) cancelButtonTitle:(NSString *)cancelTitle confirmButtonTitle:(NSString *)confirmButtonTitle
{
    [self.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
    [self.confirmButton setTitle:confirmButtonTitle forState:UIControlStateNormal];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self.animator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self.animator;
}

@end