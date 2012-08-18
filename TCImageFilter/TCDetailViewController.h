//
//  TCDetailViewController.h
//  TCImageFilter
//
//  Created by Lee Tze Cheun on 8/4/12.
//  Copyright (c) 2012 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) CIFilter *filter;
           
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
