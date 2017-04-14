//
//  AWSCognitoUserPoolsSignInProvider.m
//  AWSCognitoUserPoolsSignIn
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//

#import "AWSCognitoUserPoolsSignInProvider.h"
#import <AWSMobileHubHelper/AWSSignInManager.h>

NSString *const AWSCognitoUserPoolsSignInProviderKey = @"CognitoUserPools";

typedef void (^AWSSignInManagerCompletionBlock)(id result, AWSIdentityManagerAuthState authState, NSError *error);

@interface AWSSignInManager()

- (void)completeLogin;

@end

@interface AWSCognitoUserPoolsSignInProvider()

@property (strong, nonatomic) UIViewController *signInViewController;
@property (atomic, copy) AWSSignInManagerCompletionBlock completionHandler;
@property (strong, nonatomic) id<AWSCognitoUserPoolsSignInHandler> interactiveAuthenticationDelegate;

@end

@implementation AWSCognitoUserPoolsSignInProvider

static NSString *idpName;

+ (void)setupUserPoolWithId:(NSString *)cognitoIdentityUserPoolId
cognitoIdentityUserPoolAppClientId:(NSString *)cognitoIdentityUserPoolAppClientId
cognitoIdentityUserPoolAppClientSecret:(NSString *)cognitoIdentityUserPoolAppClientSecret
                        region:(AWSRegionType)region{
    AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:region credentialsProvider:nil];
    AWSCognitoIdentityUserPoolConfiguration *configuration = [[AWSCognitoIdentityUserPoolConfiguration alloc]
                                                              initWithClientId:cognitoIdentityUserPoolAppClientId
                                                              clientSecret:cognitoIdentityUserPoolAppClientSecret
                                                              poolId:cognitoIdentityUserPoolId];
    [AWSCognitoIdentityUserPool registerCognitoIdentityUserPoolWithConfiguration:serviceConfiguration userPoolConfiguration:configuration forKey:AWSCognitoUserPoolsSignInProviderKey];
    
    idpName = [[NSString alloc] initWithFormat:@"cognito-idp.%@.amazonaws.com/%@", [cognitoIdentityUserPoolId componentsSeparatedByString:@"_"][0], cognitoIdentityUserPoolId ];
    
}

+ (instancetype)sharedInstance {
    if (![AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:AWSCognitoUserPoolsSignInProviderKey]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"User Pool not registered. The method `setupUserPoolWithId:cognitoIdentityUserPoolAppClientId:cognitoIdentityUserPoolAppClientSecret:region` has to be called once before accessing the shared instance."
                                     userInfo:nil];
        return nil;
    }
    static AWSCognitoUserPoolsSignInProvider *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[AWSCognitoUserPoolsSignInProvider alloc] init];
    });
    
    return _sharedInstance;
}

- (AWSCognitoIdentityUserPool *)getUserPool {
    return [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:AWSCognitoUserPoolsSignInProviderKey];
}

- (void)setViewControllerForUserPoolsSignIn:(UIViewController *)signInViewController {
    self.signInViewController = signInViewController;
}


#pragma mark - AWSIdentityProvider

- (NSString *)identityProviderName {
    return idpName;
}

- (AWSTask<NSString *> *)token {
    AWSCognitoIdentityUserPool *pool = [self getUserPool];
    return [[[pool currentUser] getSession] continueWithSuccessBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserSession *> * _Nonnull task) {
        return [AWSTask taskWithResult:task.result.idToken.tokenString];
    }];
}

- (BOOL)isLoggedIn {
    AWSCognitoIdentityUserPool *pool = [self getUserPool];
    return [pool.currentUser isSignedIn];
}

- (void)reloadSession {
    if ([self isLoggedIn]) {
        [self completeLogin];
    }
}

- (void)completeLogin {
    [[AWSSignInManager sharedInstance] completeLogin];
}

- (void)setInteractiveAuthDelegate:(id)interactiveAuthDelegate {
    self.interactiveAuthenticationDelegate = interactiveAuthDelegate;
    [self getUserPool].delegate = interactiveAuthDelegate;
}

- (void)login:(AWSSignInManagerCompletionBlock) completionHandler {
    self.completionHandler = completionHandler;
    AWSCognitoIdentityUserPool *pool = [self getUserPool];
    [[pool.getUser getSession] continueWithSuccessBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserSession *> * _Nonnull task) {
        [self completeLogin];
        return nil;
    }];
    [self.interactiveAuthenticationDelegate handleUserPoolSignInFlowStart];
}

- (void)logout {
    AWSCognitoIdentityUserPool *pool = [self getUserPool];
    [pool.currentUser signOut];
}

- (BOOL)interceptApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)interceptApplication:(UIApplication *)application
                     openURL:(NSURL *)url
           sourceApplication:(NSString *)sourceApplication
                  annotation:(id)annotation {

    return YES;
}

@end
