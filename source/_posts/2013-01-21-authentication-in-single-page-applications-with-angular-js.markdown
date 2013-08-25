---
layout: post
title: Authentication in Single Page Applications with Angular.js
categories: [Angular.js, Development]
status: publish
type: post
published: true
comments: true
permalink: /authentication-in-single-page-applications-with-angular-js/
---
**3/6/2013 update:**
*I've done some heavy refactoring, and have now introduced an angular service to eliminate a lot of redundant code, as well as a directive which can aid in optionally displaying/hiding elements based on an access level. Please check out the [GitHub repo](https://github.com/fnakstad/angular-client-side-auth) for the latest version. The example app in the repo has been deployed to Heroku, so now you can test it out live for yourself [right here](http://angular-client-side-auth.herokuapp.com/). A separate blogpost discussing the complementing server-side code <a href="http://www.frederiknakstad.com/blog/2013/08/04/authentication-in-single-page-applications-with-angular.js-part-2/">can be found here</a>.*

I have been working a lot with Angular.js lately, and love how easy it makes it to create web applications with rich client-side functionality. It's an extremely useful asset in keeping your own client-side code lean, making it easy to separate business logic and declarative markup for anything view specific.  However, it's not all roses, and I'm still struggling to find the best solutions to some problems I have encountered. One of which is a problem that exceeds the scope of Angular...

***How do I deal with authentication and authorization in single page applications?***

Since only the initial load of the app is a full page load, and subsequent communication with the server is entirely done via XHRs I need a slightly different model from the traditional one. One option I tried out was to have a traditional login page which, on success, redirects to a secured URL which loads the actual application. This has the added benefit that the client side code and view templates used for pages intended for logged in users are not accessible to anyone not logged in. However, in many cases this is not much of a concern as long as the communication against the resource API is properly secured. Preventing anyone from getting or modifying sensitive data is a server-side issue, and should therefore be properly handled there. I wanted a seamless user experience with no full page reloads beyond the initial page load, so I decided to play around a little and see if I could come up with an alternative. These are the core characteristics of the solution I set out to implement:

1. The server needs to communicate what permissions/role the client has on inital page load.
2. The client app then needs to keep track of the user's login status, and change it accordingly when the user logs in or out. These operations should not cause a full page reload.
3. The access level of the routes should be declared as part of the rest of the routing configuration.

## Configuring access levels and user roles
To indicate the available user roles and access levels to be used in the routing system, I decided to make a separate module which could be used both on the client and server side (with Node.js):

{% gist 6031923 %}

Both the user roles and access levels are defined as numbers so that it is possible to calculate permissions using binary operations. User roles are defined by which bit is set to 1, while access levels indicate whether that user role has access by setting the corresponding bit to either 1 or 0 in the bitmask[^1]. So, here is an example of binary operations that can be calculated to see whether the user role `user` has access to the access levels `admin` and `public`:

```
   010 // = userRole: user
OR 100 // = accessLevel admin
=  000 // = false, no access

   010 // = userRole: user
OR 111 // = accessLevel public
=  010 // = true, go ahead
```

## Setting up client-side routing
When I define my routes I want to indicate what access level each route should have, so I add a new property to each route, called `access`, like so:

{% gist 6032777 %}

## Communicating login status to client side app on initial page load

When the user first loads the client side app, whether he's trying to access a restricted or public route initially, the server needs to communicate the current role of the user. Since the client side app can't decrypt the authentication cookie set by the server, I decided to communicate login status via the HTTP response which serves up the single page application. I decided on doing this by setting a cookie, which the client would clear upon reading it. I feel like there's something icky about doing it this way, so I'm open to any alternative solutions here. Anyway, the server sets the cookie like so:

{% gist 6032803 %}

On the client-side I have an Angular service, `Auth`, which upon initialization will read in this cookie, save the login status, then discard the cookie. This service will also make the access levels, user roles, and current user available to the rest of the application.

{% gist 6032854 %}

So, now my Angular app knows what login status the user has, and can perform the client side routing based on this status.

## Enforcing the routing policy client-side

**Warning: I want to stress the importance of securing your server-side API once-again. The routing policy we're "enforcing" client-side is *very* easy to get around using Chrome Developer Tools or Firebug. The technique I'm describing is used as a way of tailoring your views and giving a better user experience, but malicious users can still change their user role and get access to client-side routes that should be restricted to them. This is not a problem as long as any sensitive data is accessed via your server-side API, and the proper authentication/authorization strategy is implemented there.**

Now that I have access to the current user's role and the access level of each route I can actually enforce the policy I've configured. So now I can add functionality like logging in, registering new users, authorizing a route, etc. to the `Auth` service I mentioned earlier.

{% gist 6032902 %}

This service can easily be reused by injecting it into any other component of my Angular application. For example, to actually enforce my routing policy I need to utilize the `authorize()` and `isLoggedIn()` functions in an event handler on $routeChangeStart:

{% gist 6032970 %}

Now, whenever a route is accessed, the proper authorization check will be performed before serving up the view, and a redirect will happen in case the user has insufficient permissions.

One gotcha here is that the session could time out making the client believe the user is logged in when in fact he is declined when communicating with the server resource API. However this can be rectified by using an HTTP interceptor to detect API calls that were denied. Mine is pretty simple, and just redirects to the login page in case of a 401.

{% gist 6033015 %}

## Customizing views based on user role
I also want to introduce a directive I've made which you can use to show/hide elements based on the current user's role. Here's what it looks like:

{% gist 6033059 %}

So, whenever you decorate a tag with the `access-level` directive, it will check the role of the current user, perform an authorization check using the injected `Auth`, and then show/hide the element. It also remembers the previous `display` property of the element in case the user logs out, thus changing her role.

I really want to stress again the point that this scheme exposes all the routing logic and view templates to the client, and can easily be manipulated by the end user. So, you still have to make sure that the calls to the server are properly authenticated and authorized there.

I have made a complete example with all the code available in *[this GitHub repository](https://github.com/fnakstad/angular-client-side-auth)*, which might illustrate my approach better than I have been able to in this blogpost.

[^1]: The routingConfig module in the [GitHub repo](https://github.com/fnakstad/angular-client-side-auth) will now automatically generate the required bit masks for you!