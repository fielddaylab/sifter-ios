//
//  InnovPopOverTwitterAccountContentView.m
//  YOI
//
//  Created by Jacob Hanshaw on 7/17/13.
//
//

#import "InnovPopOverTwitterAccountContentView.h"
#import <Accounts/Accounts.h>

@interface InnovPopOverTwitterAccountContentView()
{
     NSArray *allTwitterAccounts;
     NSMutableArray *selectedTwitterAccounts;
}

@end

@implementation InnovPopOverTwitterAccountContentView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        NSArray *xibArray =  [[NSBundle mainBundle] loadNibNamed:@"InnovPopOverTwitterAccountContentView" owner:self options:nil];
        InnovPopOverTwitterAccountContentView *view = [xibArray objectAtIndex:0];
        self.frame = view.bounds;
        [self addSubview:view];
        
        selectedTwitterAccounts = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (void) setInitialTwitterAccounts:(NSArray *) twitterAccounts
{
    allTwitterAccounts = twitterAccounts;
}

- (IBAction)okButtonPressed:(id)sender
{
    [delegate setAvailableTwitterAccounts: selectedTwitterAccounts];
    [self.dismissDelegate dismiss];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [allTwitterAccounts count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    [cell.textLabel setText:((ACAccount *)[allTwitterAccounts objectAtIndex:indexPath.row]).username];
    
    //okay to compare pointers since all objects in selected come from all
    BOOL match = NO;
    for(int i = 0; i < [selectedTwitterAccounts count]; ++i)
        if([allTwitterAccounts objectAtIndex:indexPath.row] == [selectedTwitterAccounts objectAtIndex:i]) match = YES;
    
    if(match) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        [selectedTwitterAccounts removeObject: [allTwitterAccounts objectAtIndex:indexPath.row]];
    }
    else
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [selectedTwitterAccounts addObject: [allTwitterAccounts objectAtIndex:indexPath.row]];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end