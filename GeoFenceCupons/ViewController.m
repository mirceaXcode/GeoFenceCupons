//
//  ViewController.m
//  GeoFenceCupons
//
//  Created by Mircea Popescu on 10/2/18.
//  Copyright © 2018 Mircea Popescu. All rights reserved.
//

#import "ViewController.h"
#import "MapKit/MapKit.h"

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic, assign) BOOL mapIsMoving;

@property (strong, nonatomic) MKPointAnnotation *currentAnno;
@property (strong, nonatomic) MKPointAnnotation *storeAnno;

@property (strong, nonatomic) CLCircularRegion *geoRegion;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapIsMoving = NO;

    // Set up the Location Manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Make sure you set UIBackgroundModes to "location" in info.plist(it's case sensitive, Location won't work), otherwise this feature will not work
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.pausesLocationUpdatesAutomatically = YES;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 3; //meters
    
    // Zoom the map very close
    CLLocationCoordinate2D noLocation = CLLocationCoordinate2DMake(0.0,0.0);
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(noLocation, 500, 500); //500 by 500
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];

    // Create an annotation for the user's location
    [self addCurrentAnnotation];

    // Create an annotation for the store location
    [self addStoreAnnotation];

    // Setup a geoRegion object
    [self setUpGeoRegion];
    
    // Check if the device can do geofences
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] == YES){
        
        CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
        if((currentStatus != kCLAuthorizationStatusAuthorizedWhenInUse) ||
           (currentStatus != kCLAuthorizationStatusAuthorizedAlways)){
            [self.locationManager requestAlwaysAuthorization];
        }
        
        // Ask for notification permissions if the app is in the background
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
        
    }
    
    self.mapView.showsUserLocation = YES;
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringForRegion:self.geoRegion];

}

-(void) mapView:(MKMapView *) mapView regionWillChangeAnimated:(BOOL)animated{
    self.mapIsMoving = YES;
}

-(void) mapView:(MKMapView *) mapView regionDidChangeAnimated:(BOOL)animated{
    self.mapIsMoving = NO;
}

-(void) setUpGeoRegion{
    // Create the Geographic region to be monitored
    self.geoRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(30.390920,-97.747996) radius:10 identifier:@"MyRegionIdentifier"];
}

- (void) addCurrentAnnotation {
    self.currentAnno = [[MKPointAnnotation alloc] init];
    self.currentAnno.coordinate = CLLocationCoordinate2DMake(0.0, 0.0);
    self.currentAnno.title = @"My Location";
}

- (void) addStoreAnnotation{
    self.storeAnno = [[MKPointAnnotation alloc] init];
    self.storeAnno.coordinate = CLLocationCoordinate2DMake(30.390920,-97.747996);
    self.storeAnno.title = @"My Business";
    [self.mapView addAnnotation:self.storeAnno];
    
}
-(void) centerMap:(MKPointAnnotation *)centerPoint{
    [self.mapView setCenterCoordinate:centerPoint.coordinate animated:YES];
}

#pragma mark - location call backs

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    self.currentAnno.coordinate = locations.lastObject.coordinate;
    if(self.mapIsMoving == NO){
        [self centerMap:self.currentAnno];
    }
}

-(void) locationManager:(CLLocationManager *)manager didEnterRegion:(nonnull CLRegion *)region{
    
    UILocalNotification *note = [[UILocalNotification alloc] init];
    note.fireDate = nil;
    note.repeatInterval = 0;
    note.alertTitle = @"My Business Savings!";
    note.alertBody = [NSString stringWithFormat:@"Use this cupon and save 10\uFF05 for the next 30 min: ABCD1030"];
    [[UIApplication sharedApplication] scheduleLocalNotification:note];
    
}


@end
