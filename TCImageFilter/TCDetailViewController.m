//
//  TCDetailViewController.m
//  TCImageFilter
//
//  Created by Lee Tze Cheun on 8/4/12.
//  Copyright (c) 2012 Lee Tze Cheun. All rights reserved.
//

#import "TCDetailViewController.h"
#import "TCFilterNames.h"
#import "MBProgressHUD.h"

/* Core Image uses radians as the unit for its filter's input parameters. */
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#pragma mark - Private Interface

@interface TCDetailViewController ()
@property (strong, nonatomic) CIContext *context;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) UIImage *inputImage;
@property (strong, nonatomic) CIImage *blendImage;
@end

#pragma mark -

@implementation TCDetailViewController

#pragma mark - View Controller Events

- (void)viewDidLoad
{
    [super viewDidLoad];
        	
    // Store a reference to the original image before filters are applied.
    self.inputImage = self.imageView.image;
    
    // Create the Core Image context once and reuse it. It's an expensive operation.
    self.context = [CIContext contextWithOptions:nil];
}

- (void)viewDidUnload
{
    // Release all strong references.
    self.masterPopoverController = nil;
    self.inputImage = nil;
    self.blendImage = nil;
    self.filter = nil;
    self.context = nil;
        
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Split View Delegate

/* Master view controller will be hidden. So, add the bar button item to 
   display the popover. */
- (void)splitViewController:(UISplitViewController *)splitController
     willHideViewController:(UIViewController *)viewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Filters", @"Filters");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

/* Master view controller will be shown. So, remove the bar button item. */
- (void)splitViewController:(UISplitViewController *)splitController
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating
    // the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Debug Methods

/* Helper method to debug and print a filter's attributes. */
- (void)printFilterAttributes:(CIFilter *)filter
{
    NSDictionary *filterAttributes = [filter attributes];
    NSLog(@"%@: %@", [filter name], [filterAttributes description]);
}

/* Helper method to debug and print all the filter's input parameters. */
- (void)printFilterInputParameters:(CIFilter *)filter
{
    NSDictionary *filterAttributes = [filter attributes];
    NSArray *inputKeys = [filter inputKeys];
    
    for (NSString *key in inputKeys) {
        NSDictionary *inputParam = [filterAttributes objectForKey:key];
        NSLog(@"%@: %@\n", key, [inputParam description]);
    }
}

#pragma mark - Apply Filter to Image

/* Set a new filter to apply on the image. */
- (void)setFilter:(CIFilter *)newFilter
{
    if (_filter != newFilter) {
        _filter = newFilter;
        
        if (nil == _filter){
            // If filter object is nil, we remove filter applied to image.
            self.navigationItem.title = NSLocalizedString(@"Select a Filter", @"Select a Filter");
            self.imageView.image = self.inputImage;
        } else {
            // Display the filter name on the navigation bar.
            self.navigationItem.title = [[_filter attributes] objectForKey:kCIAttributeFilterDisplayName];
            
            // Configure filter's input parameters.
            [self configureFilter:_filter];
            
            // Draw output on the image view.
            // When we tell Core Image to draw the image, only then will the
            // image processing begins.
            [self drawOutputImage:[_filter outputImage]];    
        }
    }
    
    // After a filter is selected and applied the popover should be
    // dismissed automatically.
    if (self.masterPopoverController) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

/* Lazily load the image used in composite operation filters. */
- (CIImage *)blendImage
{
    if (nil == _blendImage) {
        NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"star" withExtension:@"png"];
        _blendImage = [[CIImage alloc] initWithContentsOfURL:imageURL];
    }
    return _blendImage;
}

/* Configure filter's input parameters with valid values and apply filter to image. */
- (void)configureFilter:(CIFilter *)filter
{
    NSString *filterName = [filter name];
    
    // Get the input image that we will apply the filter on.
    UIImage *imageToFilter = self.inputImage;
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:imageToFilter.CGImage];
    [filter setValue:inputImage forKey:kCIInputImageKey];
                    
    // Set the filter's input parameters values.
    if ([filterName isEqualToString:kCISepiaTone])
    {
        [filter setValue:@1.00 forKey:@"inputIntensity"];
    }
    else if ([filterName isEqualToString:kCIColorMonochrome])
    {
        // Draw image using gray scale color.
        CIColor *color = [CIColor colorWithRed:0.7f green:0.7f blue:0.7f alpha:1.0];
        [filter setValue:color forKey:@"inputColor"];
        [filter setValue:@1.00 forKey:@"inputIntensity"];
    }
    else if ([filterName isEqualToString:kCIVignette])
    {
        // Set maximum values for the vignette effect.
        [filter setValue:@1.00 forKey:@"inputIntensity"];
        [filter setValue:@2.00 forKey:@"inputRadius"];
    }
    else if ([filterName isEqualToString:kCIHueAdjust])
    {
        [filter setValue:@(DEGREES_TO_RADIANS(-90.0)) forKey:@"inputAngle"];
    }
    else if ([filterName isEqualToString:kCIExposureAdjust])
    {
        // Set maximum exposure to make the effect more obvious.
        [filter setValue:@2.00 forKey:@"inputEV"];
    }
    else if ([filterName isEqualToString:kCITemperatureAndTint])
    {
        // Control the temperature and tint of the image.
        [filter setValue:[[CIVector alloc] initWithX:6500 Y:0] forKey:@"inputNeutral"];
        [filter setValue:[[CIVector alloc] initWithX:13000 Y:230] forKey:@"inputTargetNeutral"];
    }
    else if ([filterName isEqualToString:kCIColorControls])
    {
        // Control the image's Brightness, Contrast and Saturation.
        [filter setValue:@0.00 forKey:@"inputBrightness"];
        [filter setValue:@1.80 forKey:@"inputContrast"];
        [filter setValue:@2.00 forKey:@"inputSaturation"];
    }
    else if ([filterName isEqualToString:kCIHighlightShadowAdjust])
    {
        // Make the shadows as dark as possible.
        [filter setValue:@1.0 forKey:@"inputHighlightAmount"];
        [filter setValue:@-1.0 forKey:@"inputShadowAmount"];
    }
    else if ([filterName isEqualToString:kCICrop])
    {
        // Crop from the center of the image.
        CIVector *cropRect = [[CIVector alloc] initWithX:100.0f Y:100.0f
                                                       Z:300.0f W:300.0f];
        [filter setValue:cropRect forKey:@"inputRectangle"];
    }
    else if ([filterName isEqualToString:kCIStraightenFilter])
    {
        // Rotates the image 45 degrees clockwise.
        // The image is scaled and cropped so that the rotated image fits
        // the extent of the input image.
        [filter setValue:@(DEGREES_TO_RADIANS(-45.0f)) forKey:@"inputAngle"];
    }
    else if ([filterName isEqualToString:kCIAffineTransform])
    {
        // Rotate the image 45 degrees clockwise and scale it down
        // to 75% of original size.
        CGAffineTransform transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-45));
        transform = CGAffineTransformScale(transform, 0.75, 0.75);
        [filter setValue:[NSValue valueWithCGAffineTransform:transform]
                  forKey:@"inputTransform"];
    }
    else if ([self filter:filter inCategory:kCICategoryCompositeOperation])
    {
        // Blending 2 images together.
        // This is similar to Photoshop blending 2 layers together.
        if ([filterName isEqualToString:kCISourceInCompositing] ||
            [filterName isEqualToString:kCISourceOutCompositing])
        {            
            // Swap the input image and overlay image to observe this filter effect.
            [filter setValue:inputImage forKey:kCIInputImageKey];
            [filter setValue:self.blendImage forKey:kCIInputBackgroundImageKey];
        }
        else
        {
            [filter setValue:self.blendImage forKey:kCIInputImageKey];
            [filter setValue:inputImage forKey:kCIInputBackgroundImageKey];
        }
    }
}

/* Draw result onto the image view. */
- (void)drawOutputImage:(CIImage *)outputImage
{
    // Show progress HUD because image processing will take a while.
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
    // Drawing the image is a processor-intensive operation. So, we perform
    // the rendering asynchronously. When the image is ready, we will display
    // it on the image view.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Render the resulting image.
        CGImageRef cgimage = [self.context createCGImage:outputImage
                                                fromRect:[outputImage extent]];
        
        // Image is now ready for display. Switch back to main thread to
        // update UI.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [UIImage imageWithCGImage:cgimage];
            
            // Remember to release the CGImageRef struct that we created.
            CGImageRelease(cgimage);
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
}

/* Returns YES if filter is under specified category; NO otherwise. */
- (BOOL)filter:(CIFilter *)filter inCategory:(NSString *)category
{
    NSArray *filterCategories = [[filter attributes] objectForKey:
                                 kCIAttributeFilterCategories];
    return [filterCategories containsObject:category];
}

@end
