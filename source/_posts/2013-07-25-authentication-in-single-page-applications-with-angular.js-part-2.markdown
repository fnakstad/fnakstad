---
layout: post
title: Authentication in Single Page Applications with Angular.js Part 2
tags: Angular.js Development Express Node.js Passport.js
published: false
comments: true
---
As you may have gathered from the title, this is a follow-up to <a href="http://www.frederiknakstad.com/authentication-in-single-page-applications-with-angular-js/">a post I wrote a some time ago</a> regarding role-based authentication/authorization in single page applications. This time I'd like to highlight how I implemented the server-side code that complements my client-side solution. 

<strong>Since you can never trust that the requests you get from the client haven't been tampered with, it's paramount to have a good authentication/authorization strategy on the server. The client-side authentication scheme I introduced earlier is simply a convenient way to adapt the user interface - proper authentication/authorization should always be left up to the server-side.</strong> 

I am using Node.js/Express along with the excellent Passport.js authentication middleware, but hopefully it shouldn't be too much bother to apply the same patterns to other server-side frameworks. You can see an example of this scheme implemented in <a href="https://github.com/fnakstad/angular-client-side-auth">this GitHub repo</a>, and I have a live version of it <a href="http://angular-client-side-auth.herokuapp.com/">running on Heroku</a>. Well, let's get right to it!

Node.js/Express is very non-prescriptive in terms of telling you how to lay out your code, so I'll try to give a quick overview how I lay out my projects first. When working with Node.js/Angular I usually divide my code into server and client directories, and then split my server side code into controllers and models. so my directory structure usually looks something like this:

<a href="http://www.frederiknakstad.com/wp-content/uploads/2013/06/project_layout.png"><img src="http://www.frederiknakstad.com/wp-content/uploads/2013/06/project_layout.png" alt="project_layout" width="381" height="404" class="aligncenter size-full wp-image-404" /></a>

So, the <strong>client</strong> directory contains all my client-side Javascript (including all my Angular.js code), HTML, and CSS resources. The client folder is served as a static directory structure. My <strong>server</strong> directory contains the code for defining my REST API. 

The entry point is the <strong>server.js</strong> file in the root where I configure Express, set up middleware, and then delegate routing to another file called <strong>routes.js</strong>. <strong>routes.js</strong> in turn defines my routes, their access levels, middleware, and in the end hands off the responsibility to a handler defined in one of my controllers.

client
// This is where I keep any client-side Javascript (So, all my Angular.js code), HTML, and CSS resources
- css
- js
- views
server
- controllers
- models
- routes.js
server.js
// entry point, instantiate server, middleware registration

Common user-roles/access-levels module
As you might remember from my first post, I made a module wherein I declared all user roles and access levels. I used a little trick to make this module usable both in the browser and by Node.js, so in case you forgot here's what the code looks like:

<pre>
[javascript]

[/javascript]
</pre>

EnsureAuthorized middleware
The next step is to create a middleware component which can be used to authorize an HTTP request based on the

Routing setup
 So, usually I'll have a routes.js file where I declare all
