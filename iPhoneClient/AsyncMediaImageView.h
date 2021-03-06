//
//  AsyncMediaImageView.h
//  ARIS
//
//  Created by David J Gagnon on 11/18/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "Media.h"
#import "ARISMoviePlayerViewController.h"

@protocol AsyncMediaImageViewDelegate <NSObject>
@optional
-(void) imageFinishedLoading;
@end


@interface AsyncMediaImageView : UIImageView {
//	NSURLConnection* connection; //keep a reference to the connection so we can cancel download in dealloc
//	NSMutableData* data; //keep reference to the data so we can collect it as it downloads
//	Media *media; //keep a refrence so we can update the media with the data after it is loaded
//    ARISMoviePlayerViewController *mMoviePlayer; //In case we need to load a frame of a movie
//    id <AsyncMediaImageViewDelegate> __unsafe_unretained delegate;
//	BOOL isLoading;
 //   BOOL loaded;
    
}

@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSMutableData* data;
@property (nonatomic, strong) Media *media;
@property (nonatomic, strong) ARISMoviePlayerViewController *mMoviePlayer;
@property (nonatomic, unsafe_unretained) id <AsyncMediaImageViewDelegate> delegate;

@property(readwrite,assign)BOOL isLoading;
@property(readwrite,assign)BOOL loaded;
@property(readwrite,assign)BOOL dontUseImage;

- (id)   initWithFrame:(CGRect)aFrame andMedia:(Media *)aMedia;
- (id)   initWithFrame:(CGRect)aFrame andMediaId:(int)mediaId;
- (void) loadImageFromMedia:(Media *) aMedia;
- (void) setImage:(UIImage*) image;
- (void) updateViewWithNewImage:(UIImage*)image;
- (void) reset;

- (void) startSpinner;
- (void) stopSpinner;
- (void) setSpinnerColor: (UIColor *) color;

@end


