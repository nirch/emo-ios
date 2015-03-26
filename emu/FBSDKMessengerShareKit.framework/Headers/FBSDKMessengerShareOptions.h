// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "FBSDKMessengerContext.h"

/*!
 @class FBSDKMessengerShareOptions

 @abstract
 Optional parameters that change the way content is shared into Messenger
 */
@interface FBSDKMessengerShareOptions : NSObject

/*!
 @abstract Pass additional information to be sent to Messenger which is sent back to
 the user's app when they reply to an attributed message.
 */
@property (nonatomic, readwrite, copy) NSString *metadata;

/*!
 @abstract Describes the way the content is to be shared in Messenger.
 */
@property (nonatomic, readwrite, strong) FBSDKMessengerContext *context;

/*!
@abstract Optional property describing the www source URL of the content

@discussion Setting this property improves performance by allowing Messenger to download
 the content directly rather than uploading the content from your app.
 This option is only used for animated GIFs and WebPs
*/
@property (nonatomic, readwrite, copy) NSURL *sourceURL;

@end
