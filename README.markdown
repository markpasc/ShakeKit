ShakeKit
=========================

* Created by [Justin Williams](http://carpeaqua.com)

What is ShakeKit?
-------------------------

ShakeKit is an Objective-C wrapper for the super awesome [mlkshk.com](http://mlkshk.com).  With it you can (hopefully) create awesome Mac and iOS applications that take advantage of the service.

As of 05/28/2011 it wraps every method available from mlkshk's [developer API page](http://mlkshk.com/developers).  That should allow you to do the following

* Upload a new image to your shake
* Get your shake timeline
* Get user profile info
* Get your shake timeline before or after a certain file

How Do I Use It?
-------------------------

There's presently no sample project, but here's the general idea of how to get this thing fired up:

1. Get a set of API keys from [http://mlkshk.com/developers](http://mlkshk.com/developers).
2. Create a new Xcode 4 workspace and include ShakeKit as a project in it.
3. Drag ShakeKit.h into your main app's project.
4. Get your OAuth2 token and secret by calling `loginWithUsername:password:withCompletionHandler` from your login view controller.   This will store the token and secret to NSUserDefaults so you shouldn't need it again.  


Find this useful?
-------------------------

If you have found this useful, please consider supporting my company [Second Gear](http://www.secondgearsoftware.com/) by purchasing or recommending our products.  I'm also a sucker for stuff on my [Amazon wishlist](http://amzn.com/w/97E89VZWC7HT).

All The Other Stuff
-------------------------

If you have any ideas for how to improve this, please file issues.  Patches welcome, etc.

---------------------------------------

* **1.0** Original release