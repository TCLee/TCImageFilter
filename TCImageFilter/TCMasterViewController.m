//
//  TCMasterViewController.m
//  TCImageFilter
//
//  Created by Lee Tze Cheun on 8/4/12.
//  Copyright (c) 2012 Lee Tze Cheun. All rights reserved.
//

#import "TCMasterViewController.h"
#import "TCDetailViewController.h"
#import "TCFilterNames.h"

#pragma mark - Private Interface

@interface TCMasterViewController ()
@property (strong, nonatomic) TCDetailViewController *detailViewController;
@property (nonatomic, strong) NSArray *categoriesList;
@property (nonatomic, strong) NSDictionary *filtersDict;
@end

#pragma mark -

@implementation TCMasterViewController

#pragma mark - View Lifecycle

- (void)awakeFromNib
{
    // Create the filters that we want to apply on the sample image.
    [self loadFilters];
            
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    	
    // Get the reference to the detail view controller from our
    // split view controller.
    self.detailViewController = (TCDetailViewController *)
        [[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewDidUnload
{
    // Release any strong references.
    self.categoriesList = nil;
    self.filtersDict = nil;
    
    [super viewDidUnload];
}

#pragma mark - Device Rotation

/* On an iPad device, we should support all orientations. */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UI Button Actions

/* User tap the "Clear" button to remove filter from image. */
- (IBAction)clearFilter:(id)sender
{
    // Deselect the selected filter row on the table view.
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
                                  animated:YES];
    
    // Pass nil to detail view controller to remove the filter.
    self.detailViewController.filter = nil;
}

#pragma mark - Table View Data Source

/* Number of filter categories. */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.categoriesList count];
}

/* Number of filters in a category. */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *category = [self.categoriesList objectAtIndex:section];
    NSArray *filters = [self.filtersDict objectForKey:category];
    return [filters count];
}

/* Filter category title. */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.categoriesList objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FilterCell"];
    
    NSString *category = [self.categoriesList objectAtIndex:indexPath.section];
    NSArray *filters = [self.filtersDict objectForKey:category];
    cell.textLabel.text = [filters objectAtIndex:indexPath.row];
    return cell;    
}

#pragma mark - Table View Delegate

/* User selects a filter from the list to apply to the image. */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Pass the selected filter object to the detail view controller.
    NSString *category = [self.categoriesList objectAtIndex:indexPath.section];
    NSArray *filters = [self.filtersDict objectForKey:category];
    CIFilter *filter = [CIFilter filterWithName:[filters objectAtIndex:indexPath.row]];
    [filter setDefaults];
    self.detailViewController.filter = filter;
}

#pragma mark - Debug Methods

/* Helper method to debug and print all available filters on current platform. */
- (void)printFiltersInCategory:(NSString *)category
{
    NSArray *filters = [CIFilter filterNamesInCategory:category];
    NSLog(@"%@", [filters description]);
}

#pragma mark - Load Filters

/* Create the list of filters that we want to use on the image. */
- (void)loadFilters
{
    // We'll separate the filters into different categories.
    self.categoriesList = @[
        kCICategoryColorAdjustment, kCICategoryColorEffect,
        kCICategoryStylize, kCICategoryGeometryAdjustment,
        kCICategoryCompositeOperation
    ];
    
    // Category is the key and the value is the list of filters under the category.
    self.filtersDict = @{
        kCICategoryColorAdjustment : @[ kCIExposureAdjust, kCIColorControls,
            kCIHueAdjust, kCITemperatureAndTint ],
        kCICategoryColorEffect : @[ kCISepiaTone, kCIColorMonochrome, kCIVignette ],
        kCICategoryStylize : @[ kCIHighlightShadowAdjust ],
        kCICategoryGeometryAdjustment : @[ kCICrop, kCIStraightenFilter,
            kCIAffineTransform ],
        kCICategoryCompositeOperation : @[
            kCIAdditionCompositing, kCIColorBlendMode,
            kCIColorBurnBlendMode, kCIColorDodgeBlendMode,
            kCILightenBlendMode, kCIDarkenBlendMode, kCIDifferenceBlendMode,
            kCIExclusionBlendMode, kCISoftLightBlendMode, kCIHardLightBlendMode,
            kCIHueBlendMode, kCILuminosityBlendMode, kCIMultiplyBlendMode,
            kCIOverlayBlendMode, kCISaturationBlendMode, kCIScreenBlendMode,
            kCISourceInCompositing, kCISourceOutCompositing ]
    };
}

@end
