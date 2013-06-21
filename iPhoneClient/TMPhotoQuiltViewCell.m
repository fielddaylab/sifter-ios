//
//  TMQuiltView
//
//  Created by Bruno Virlet on 7/20/12.
//
//  Copyright (c) 2012 1000memories

//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
//  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
//  DEALINGS IN THE SOFTWARE.
//


#import "TMPhotoQuiltViewCell.h"

#import "AsyncMediaImageView.h"

#define ICON_WIDTH  40
#define ICON_HEIGHT 40

@implementation TMPhotoQuiltViewCell

@synthesize photoView = _photoView;
@synthesize categoryIconView = _categoryIconView;
@synthesize xMargin, yMargin;

- (void)dealloc {
    [_photoView release], _photoView = nil;
    
    [super dealloc];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        _photoView = [[AsyncMediaImageView alloc] init];
        _photoView.clipsToBounds = YES;
        [self addSubview:_photoView];
    }
    return _photoView;
}

- (UIImageView *)categoryIconView
{
    if (!_categoryIconView)
    {
        _categoryIconView = [[UIImageView alloc] init];
        _categoryIconView.clipsToBounds = YES;
        [self addSubview:_categoryIconView];
    }
    return _categoryIconView;
}

- (void)layoutSubviews
{
    self.photoView.frame = CGRectInset(self.bounds, xMargin, yMargin);
    self.categoryIconView.frame = CGRectMake(xMargin+self.photoView.frame.size.width-ICON_WIDTH, yMargin, ICON_WIDTH, ICON_HEIGHT);
}

@end
