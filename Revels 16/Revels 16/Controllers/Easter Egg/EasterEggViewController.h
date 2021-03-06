//
//  EasterEggViewController.h
//  Revels 16
//
//  Created by Avikant Saini on 2/10/16.
//  Copyright © 2016 LUG. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PresentationType) {
	PresentationTypeXY,
	PresentationTypeYZ,
	PresentationTypeZX,
};

@interface EasterEggViewController : UIViewController

@property (nonatomic) PresentationType ptype;

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIImage *centerImage;

@property (nonatomic, strong) NSString *lugText;
@property (nonatomic, strong) NSString *manipalText;

@property (nonatomic, strong) NSString *quote;


@end
