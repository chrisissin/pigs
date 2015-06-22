//
//  PigViewController.m
//  Pig
//
//  Created by Chris (hsin-yuan) Ho on 5/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "PigViewController.h"

@implementation PigViewController

@synthesize webView;

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:webView];
    NSString *fullURL = @"http://brightturn.tpcity.corp.yahoo.com:38/pigs/html/pig.html"; NSURL *url = [NSURL URLWithString:fullURL]; NSURLRequest *requestObj = [NSURLRequest requestWithURL:url]; [webView loadRequest:requestObj];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
/*
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    [self.view addSubview:webView];
    NSString *fullURL = @"http://yahoo.com"; NSURL *url = [NSURL URLWithString:fullURL]; NSURLRequest *requestObj = [NSURLRequest requestWithURL:url]; [webView loadRequest:requestObj];
}
*/
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [self becomeFirstResponder];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake) {
        // It has shaked
        [self.view addSubview:webView];
        [webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');"  
         "script.type = 'text/javascript';"  
         "script.text = \"function myFunction() { "  
         "alert(11111);"  
         "}\";"  
         "document.getElementsByTagName('head')[0].appendChild(script);"];  
        
        [webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];         

        NSString *fullURL = @"http://brightturn.tpcity.corp.yahoo.com:38/pigs/html/pig.html"; NSURL *url = [NSURL URLWithString:fullURL]; NSURLRequest *requestObj = [NSURLRequest requestWithURL:url]; [webView loadRequest:requestObj];        
    }
}

@end
