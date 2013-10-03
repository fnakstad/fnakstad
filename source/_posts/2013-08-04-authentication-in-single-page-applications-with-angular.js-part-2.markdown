---
layout: post
title: Authentication in Single Page Applications with Angular.js Part 2
categories: [Angular.js, Development, Express, Node.js, Passport.js]
published: false
comments: true
---
As you may have gathered from the title, this is a follow-up to <a href="http://www.frederiknakstad.com/authentication-in-single-page-applications-with-angular-js/">a post I wrote a some time ago</a> regarding role-based authentication/authorization in single page applications. This time I'd like to highlight how I implemented routing and authorization in the Node.js server that complements my Angular client.

**Since you can never trust that the client code hasn’t been tampered with by the user, it’s paramount to have a good authentication/authorization strategy on the server. The client-side auth scheme I introduced earlier is simply a convenient way to customize the user interface – proper authentication/authorization should always be left up to the server-side.** 

I am using Node.js/Express along with the excellent Passport.js authentication middleware, but hopefully it shouldn't be too much bother to apply the same patterns to other server-side frameworks. You can see an example of this scheme implemented in <a href="https://github.com/fnakstad/angular-client-side-auth">this GitHub repo</a>, and I have a live version of it <a href="http://angular-client-side-auth.herokuapp.com/">running on Heroku</a>. 

Well, let's get right to it!

## Project layout

Node.js/Express is very non-prescriptive in terms of dictating how to lay out your code, so I’ll try to give a quick overview how I structure my projects first. When working with Node.js/Angular I usually divide my code into server and client directories, and then split my server side code into controllers and models. So my directory structure will look something like this:

{% img /images/posts/2013-08-04-authentication-in-single-page-applications-with-angular.js-part-2/project_layout.png %}

The **client** directory contains all my client-side Javascript (including all my Angular.js code), HTML, and CSS resources. This is because I want a clear division between the resources that will be running in the browser and those that will be run server-side. The client folder is served as a static directory structure by Node.js. My **server** directory contains the code for defining my REST API. So, when the client has been downloaded in the user’s browser it will communicate with the server by sending XHRs to fetch data, login/logout users, fetch partial views, and so on. The starting point is the **server.js** file in the root directory where I bootstrap the server application by configuring Express and Passport and setting up other middleware components.

## Routing

Before I actually start up the server in **server.js** I will register my own routes by calling the module defined in **routes.js**. Let’s take a closer look at it.

{% gist 6116325 %}

Since I want to set up my server-side routes somewhat similarly to how I did on the client-side, I create an array called routes which contains objects defining each route. This gives me the freedom to customize what kind of metadata I want to associate with each route. These are the properties I expect in a route object:

Property    | Description
------------|-------------
**path**        | The url you want the route to map to
**httpMethod**  | HTTP Method, GET, POST, PUT, or DELETE
**middleware**  | An array of functions which will be executed in the order left to right
**accessLevel** | The access level of the route. If the user requesting the route doesn’t have access a 403 Unauthorized will be returned. If this property is not present, an access level of public is assumed.

<br />

## Authorization

One of the more interesting properties here is the <code>accessLevel</code> property, which is used to restrict access to the route for certain user roles. This property is not required unless you want to restrict access to a route for a certain set of users. As you might remember from <a href="http://www.frederiknakstad.com/authentication-in-single-page-applications-with-angular-js/">my previous post</a>, I made a module wherein I declared all user roles and access levels. I used a little trick to make this module usable both in the browser and by Node.js. This ensures that the values used to define access levels and user roles are equal on the server- and client-side. Of course the end-user can tamper with the values in his browser, but that won’t affect what’s running server-side. This is why I have been stressing the point that you need to make sure your server-side resources are properly secured. In case you forgot, here’s what the code looks like:

{% gist 6031923 %}

To enforce the access levels I’ve set on my routes I made a middleware component. This middleware component will calculate whether the current user has access to the requested route using a bitwise AND operation on the access level of the route and role of the requesting user. If the user is found to not have access the sever will respond with a HTTP 403, and break out of the middleware chain. You might also notice that I fall back on the respective <code>public</code> values for access levels and user roles by default if no user is logged in or if the route does not contain the accessLevel property.

{% gist 6165691 %}

So, now I need to register my routes with express and make sure that the <code>ensureAuthorized</code> middleware is run on all of them. I usually perform this logic in the function I export from the **routes.js** file, so that I can easily call it, and thus register my routes, from my **server.js** file. The function loops over the <code>routes</code> array, prepending each route’s middleware arrays with the <code>ensureAuthorized</code> component, and then registering it with express according to the other route metadata.

{% gist 6150416 %}

And that’s it! I want to remind that you can see a more comprehensive example in <a href="https://github.com/fnakstad/angular-client-side-auth">this Github repo</a>. If you want a better understanding of how this approach works, I highly recommend that you clone and mess around with it a little bit. And if you have any questions or issues, just post a comment here or an issue on Github.