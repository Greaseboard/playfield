//
//  TimerView.m
//  PlayField
//
//  Created by Emily Jeppson on 3/30/13.
//  Copyright (c) 2013 Jai. All rights reserved.
//

#import "TimerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TimerView{
    NSTimeInterval startTime;
    NSTimeInterval pauseTime;
    NSTimeInterval manualTime;
    bool timerRunning;
    
    NSTimeInterval playStartTime;
    NSTimeInterval playPauseTime;
    bool playTimerRunning;
    CGRect originalFrame;
}

- (id)initWithFrame:(CGRect)aRect{
    //override the frame so this component is always fills the bottom of the screen
    CGRect frame = self.superview.frame;
    frame.size.height = 49;
    frame.size.width = self.superview.frame.size.width;
    frame.origin.y = self.superview.frame.size.height - 49;
    self = [super initWithFrame:frame];
    return self;
}

- (void)awakeFromNib
{
    if(!self.initialStartTime){
        self.initialStartTime = 15 * 60; // 15 minutes default
    }
    self.contentView = [[[NSBundle mainBundle] loadNibNamed:@"TimerView" owner:self options:nil] objectAtIndex:0];
    [self addSubview:self.contentView];
    // set the background
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.65];
    
    // set the frame
    CGRect frame = self.superview.frame;
    frame.size.height = 49;
    frame.origin.y = self.superview.frame.size.height - 49;
    self.frame = frame;
    
    frame = self.frame;
    frame.origin.y = 0;
    self.contentView.frame = frame;
    
    
    // add a shine to the background
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
        shineLayer.colors = [NSArray arrayWithObjects:
                                   (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                                   (id)[UIColor colorWithWhite:1.0f alpha:0.0f].CGColor,
                                   nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:0.0f],
                                  [NSNumber numberWithFloat:0.2f],
                                  nil];
    shineLayer.frame = frame;
    [self.contentView.layer insertSublayer:shineLayer above:self.contentView.layer];
    
    //move to the far right & add border
    CALayer *layer = [self.timerBorder layer];
    [layer setCornerRadius:5.0f];
    [layer setBorderColor:[UIColor blackColor].CGColor];
    [layer setBorderWidth:1.0f];
    frame = self.timerBorder.frame;
    frame.origin.x = self.contentView.frame.size.width - self.timerBorder.frame.size.width - 10;
    frame.origin.y = 3;
    self.timerBorder.frame = frame;
    
    // play timer
    layer = [self.playContentView layer];
    [layer setCornerRadius:5.0f];
    [layer setBorderColor:[UIColor blackColor].CGColor];
    [layer setBorderWidth:1.0f];
    frame = self.playContentView.frame;
    frame.origin.x = self.contentView.frame.size.width - self.timerBorder.frame.size.width - self.playContentView.frame.size.width - 30;
    frame.origin.y = 3;
    self.playContentView.frame = frame;
    
    // gestures
    //UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGameTime:)];
    //[self.timerBorder addGestureRecognizer:tapGesture];
    
    // initialize
    timerRunning = NO;
    playTimerRunning = NO;
    [self resetTimer:self];
    [self resetPlayTime:self];
}

- (IBAction)toggleStartStop:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"Timer - toggleStartStop"]];
    timerRunning = !timerRunning;
    if(!timerRunning){ // stop the timer
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        self.resetButton.enabled = YES;
        self.startButton.enabled = YES;
        pauseTime = [NSDate timeIntervalSinceReferenceDate];
    } else { // start the timer
        [self.startButton setTitle:@"Pause" forState:UIControlStateNormal];
        self.resetButton.enabled = NO;
        if(startTime == self.initialStartTime){
            startTime = [NSDate timeIntervalSinceReferenceDate] + self.initialStartTime;
        } else if(startTime == manualTime){
            startTime = [NSDate timeIntervalSinceReferenceDate] + manualTime;
        }
        if(pauseTime > 0){ // account for pausing (stopping without resetting)
            NSTimeInterval pauseElapse = [NSDate timeIntervalSinceReferenceDate] - pauseTime;
            pauseTime = 0;
            startTime = startTime + pauseElapse;
        }
        [self updateTime];
    }
}


- (IBAction)resetTimer:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"Timer - reset"]];
    
    if(timerRunning){
        [self toggleStartStop:nil];
    }
    self.resetButton.enabled = NO;
    startTime = self.initialStartTime;
    pauseTime = 0;
    [self setTimerLabelForInterval:startTime forLabel:self.timerLabel];
}

- (IBAction)changeTime:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"Timer - change time"]];
    //[self.parent performSegueWithIdentifier:@"showTimeChanger" sender:self];    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Game Clock" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
    message.alertViewStyle = UIAlertViewStylePlainTextInput;
    [message textFieldAtIndex:0].clearButtonMode = UITextFieldViewModeAlways;
    [message textFieldAtIndex:0].text = self.timerLabel.text;
    [[message textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    [message show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Done"])
    {
        UITextField *newTime = [alertView textFieldAtIndex:0];
        [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"Timer - change time to %@", newTime.text]];
        NSString *inputText = newTime.text;
        NSRange match = [inputText rangeOfString:@":"];
        NSString *minutes = [inputText substringToIndex:match.location];
        NSString *seconds = [inputText substringFromIndex:(match.location + 1)];
        manualTime = minutes.intValue * 60 + seconds.intValue;
        if(timerRunning){
            [self toggleStartStop:nil];
        }
        startTime = manualTime;
        pauseTime = 0;
        [self setTimerLabelForInterval:startTime forLabel:self.timerLabel];

    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    NSString *inputText = [[alertView textFieldAtIndex:0] text];
    NSRange match = [inputText rangeOfString:@":"];
    if( match.length > 0 ){
        NSString *minutes = [inputText substringToIndex:match.location];
        NSString *seconds = [inputText substringFromIndex:(match.location + 1)];
        NSLog(@"%@,%@",minutes,seconds);
        if(minutes.intValue > 0 || seconds.intValue > 0){
            return YES;
        }
    }
    return NO;
}

- (IBAction)togglePlayStartStop:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"Timer - toggleStartStop"]];
    playTimerRunning = !playTimerRunning;
    if(!playTimerRunning){ // stop the timer
        [self.playStartButton setTitle:@"Start" forState:UIControlStateNormal];
        self.playResetButton.enabled = YES;
        self.playStartButton.enabled = YES;
        playPauseTime = [NSDate timeIntervalSinceReferenceDate];
    } else { // start the timer
        [self.playStartButton setTitle:@"Pause" forState:UIControlStateNormal];
        self.playResetButton.enabled = NO;
        if(playStartTime == 25){
            playStartTime = [NSDate timeIntervalSinceReferenceDate] + 25;
        }
        if(playPauseTime > 0){ // account for pausing (stopping without resetting)
            NSTimeInterval pauseElapse = [NSDate timeIntervalSinceReferenceDate] - playPauseTime;
            playPauseTime = 0;
            playStartTime = playStartTime + pauseElapse;
        }
        [self updatePlayTime];
    }
}

- (void) updatePlayTime{
    if(!playTimerRunning){
        return;
    }
    // calculate elapsed time
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval elapsed = playStartTime - currentTime;
    [self setTimerLabelForInterval:elapsed forLabel:self.playTimerLabel];
    if(elapsed >= 0){
        [self performSelector:@selector(updatePlayTime) withObject:self afterDelay:0.1];
    } else {
        self.playStartButton.enabled = NO;
        self.playResetButton.enabled = YES;
    }
}

- (void) updateTime{
    if(!timerRunning){
        return;
    }
    // calculate elapsed time
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval elapsed = startTime - currentTime;
    [self setTimerLabelForInterval:elapsed forLabel:self.timerLabel];
    
    if(elapsed >= 0){
        [self performSelector:@selector(updateTime) withObject:self afterDelay:0.1];
    } else {
        self.startButton.enabled = NO;
        self.resetButton.enabled = YES;
    }
}

- (void) setTimerLabelForInterval:(NSTimeInterval) timeInterval forLabel:(UILabel*)label{
    // calculate the seconds/minutes/hours
    int minutes = (int) timeInterval / 60;
    timeInterval = timeInterval - (minutes * 60);
    int seconds = (int) timeInterval;
    timeInterval = timeInterval - seconds;
    int fraction = timeInterval * 10;
    
    // update label
    if(minutes > 0){
        label.text = [NSString stringWithFormat:@"%02u:%02u.%u", minutes, seconds, fraction];
    } else {
        label.text = [NSString stringWithFormat:@"%02u.%u", seconds, fraction];
    }
}


- (IBAction)resetPlayTime:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"Timer - reset play timer"]];
    
    if(playTimerRunning){
        [self togglePlayStartStop:nil];
    }
    
    playStartTime = 25; // 25 seconds
    playPauseTime = 0;
    [self setTimerLabelForInterval:playStartTime forLabel:self.playTimerLabel];
}

/*
-(void) tapGameTime:(UITapGestureRecognizer *)recognizer{
    NSLog(@"Tapped");
    originalFrame = self.timerBorder.frame;
    CGRect newFrame = self.timerBorder.frame;
    newFrame.size.height = 200;
    newFrame.size.width = 500;
    newFrame.origin.x = self.contentView.frame.size.width / 2 - newFrame.size.width / 2;
    newFrame.origin.y = -400;
    [UIView animateWithDuration:.4 animations: ^{
        self.timerBorder.frame = newFrame;
        self.timerBorder.backgroundColor = [UIColor blackColor];
    }];
}*/
@end
