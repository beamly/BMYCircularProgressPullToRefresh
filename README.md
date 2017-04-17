# BMYCircularProgressPullToRefresh

Pull to fresh with circular progress view as used in the [Beamly iOS app](https://itunes.apple.com/gb/app/beamly-tv-by-zeebox/id454689266?mt=8).

![1](http://ugc-i.zeebox.com/uu7c909116-f781-4222-ba26-f9f6d74f5f0a/c7465b7e-60f4-48c6-8562-eccdda4399ed.gif)

This version of the pull to refresh feature can be used both on UITableViews and UICollectionViews and it has been inspired by [Sam Vermette](http://samvermette.com/)'s [SVPullToRefresh](https://github.com/samvermette/SVPullToRefresh).

When dealing with a custom pull to refresh view, often the native UIRefreshControl is not ideal as it is not customizable.
A common customization besides the pull to refresh, is to have a circular progress view with the logo of the app to show during the dragging.
This version of the pull to refresh allows to preserve the contentInset on the scrollview.

Try out the included demo project or just run `pod try BMYCircularProgressPullToRefresh` to give it a try.

Simple usage:

- copy all the classes in the `BMYCircularProgressPullToRefresh` folder into your project or install via CocoaPods adding the following line to your Podfile

```
pod "BMYCircularProgressPullToRefresh"
```

- import `BMYCircularProgressPullToRefresh.h` in your (view controller) class
- add the pull to refresh feature as so (you probably want to do to in the `viewDidLoad` method):

``` objective-c
UIImage *logoImage = [UIImage imageNamed:@"bicon.png"];
UIImage *backCircleImage = [UIImage imageNamed:@"light_circle.png"];
UIImage *frontCircleImage = [UIImage imageNamed:@"dark_circle.png"];
        
BMYCircularProgressView *progressView = [[BMYCircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)
                                                                                  logo:logoImage
                                                                       backCircleImage:backCircleImage
                                                                      frontCircleImage:frontCircleImage];
   
[self.scrollView setPullToRefreshWithHeight:60.0f actionHandler:^(BMYPullToRefreshView *pullToRefreshView){
	// reload logic, call the following line when work is done 
    [pullToRefreshView stopAnimating];
}];

[self.scrollView.pullToRefreshView setPreserveContentInset:YES];
[self.scrollView.pullToRefreshView setProgressView:progressView];
```

```objective-c
- (void)dealloc {
    [self.scrollView tearDownPullToRefresh];
}
```

# Licensing

This project is licensed under the [BSD 3-Clause license](http://opensource.org/licenses/BSD-3-Clause)

# Contributions

Note that we are not accepting pull requests at this time.
