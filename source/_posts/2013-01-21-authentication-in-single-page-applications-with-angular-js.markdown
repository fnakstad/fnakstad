---
layout: post
title: Authentication in Single Page Applications with Angular.js
tags:
- Angular JS
- Development
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  _syntaxhighlighter_encoded: '1'
---
<strong>3/6/2013 Update:</strong>
<em>I've done some heavy refactoring, and have now introduced an angular service to eliminate a lot of redundant code, as well as a directive which can aid in optionally displaying/hiding elements based on an access level. Please check out the <a href="https://github.com/fnakstad/angular-client-side-auth">GitHub repo</a> for the latest version. The example app in the repo has been deployed to Heroku, so now you can test it out live for yourself <a href="http://angular-client-side-auth.herokuapp.com/">right here</a>.</em>

I have been working a lot with Angular.js lately, and love how easy it makes it to create web applications with rich client-side functionality. It's an extremely useful asset in keeping your own client-side code lean, making it easy to separate business logic and declarative markup for anything view specific.  However, it's not all roses, and I'm still struggling to find the best solutions to some problems I have encountered. One of which is a problem that exceeds the scope of Angular...

<em><strong>How do I deal with authentication and authorization in single page applications?</strong></em>

Since only the initial load of the app is a full page load, and subsequent communication with the server is entirely done via XHRs I need a slightly different model from the traditional one. One option I tried out was to have a traditional login page which, on success, redirects to a secured URL which loads the actual application. This has the added benefit that the client side code and view templates used for pages intended for logged in users are not accessible to anyone not logged in. However, in many cases this is not much of a concern as long as the communication against the resource API is properly secured. Preventing anyone from getting or modifying sensitive data is a server-side issue, and should therefore be properly handled there. I wanted a seamless user experience with no full page reloads beyond the initial page load, so I decided to play around a little and see if I could come up with an alternative. These are the core characteristics of the solution I set out to implement:
<ol>
	<li>The server needs to communicate what permissions/role the client has on inital page load.</li>
	<li>The client app then needs to keep track of the user's login status, and change it accordingly when the user logs in or out. These operations should not cause a full page reload.</li>
	<li>The access level of the routes should be declared as part of the rest of the routing configuration.</li>
</ol>
<h4>Configuring access levels and user roles</h4>
To indicate the available user roles and access levels to be used in the routing system, I decided to make a separate module which could be used both on the client and server side (with Node.js):

<pre>
[javascript]
(function(exports){

    var userRoles = {
        public: 1, // 001
        user:   2, // 010
        admin:  4  // 100
    };

    exports.userRoles = userRoles;
    exports.accessLevels = {
        public: userRoles.public | userRoles.user | userRoles.admin, // 111
        anon:   userRoles.public,                                    // 001
        user:   userRoles.user | userRoles.admin,                    // 110
        admin:  userRoles.admin                                      // 100
    };
})(typeof exports === 'undefined'? this['routingConfig']={}: exports);
[/javascript]
</pre>

Both the user roles and access levels are defined as numbers so that it is possible to calculate permissions using binary operations. User roles are defined by which bit is set to 1, while access levels indicate whether that user role has access by setting the corresponding bit to either 1 or 0.
<h4>Setting up client-side routing</h4>
When I define my routes I want to indicate what access level each route should have, so I add a new property to each route, called <code>access</code>, like so:

<pre>
[javascript]

angular.module('myApp', ['myApp.services', 'ngCookies'])
.config(['$routeProvider', '$locationProvider',
    function ($routeProvider, $locationProvider) {

    ...

    var access = routingConfig.accessLevels;

    $routeProvider.when('/register',
        {
            templateUrl:    'partials/register',
            controller:     RegisterCtrl,
            access:         access.anon
        });
    $routeProvider.when('/private',
        {
            templateUrl:    'partials/private',
            controller:     PrivateCtrl,
            access:         access.user
        });
    $routeProvider.when('/admin',
        {
            templateUrl:    'partials/admin',
            controller:     AdminCtrl,
            access:         access.admin
        });

    ...

}])
[/javascript]
</pre>
<h4>Communicating login status to client side app on initial page load</h4>
When the user first loads the client side app, whether he's trying to access a restricted or public route initially, the server needs to communicate the current role of the user. Since the client side app can't decrypt the authentication cookie set by the server, I decided to communicate login status via the HTTP response which serves up the single page application. I decided on doing this by setting a cookie, which the client would clear upon reading it. I feel like there's something icky about doing it this way, so I'm open to any alternative solutions here. Anyway, the server sets the cookie like so:
<pre>
[javascript]
app.get('/*', function(req, res){
    var role = userRoles.public, username = '';
    if(req.user) {
        role = req.user.role;
        username = req.user.username;
    }

    res.cookie('user', JSON.stringify({
        'username': username,
        'role': role
    }));

    res.render('index');
});
[/javascript]
</pre>

On the client-side I have an Angular service which upon initialization will read in this cookie, save the login status to a user on the <code>$rootScope</code>, then discard the cookie.

<pre>
[javascript]
angular.module('angular-client-side-auth')
.factory('Auth', function($http, $rootScope, $cookieStore){

    ...

    $rootScope.user = $cookieStore.get('user') || { username: '', role: userRoles.public };
    $cookieStore.remove('user');

    ...

});
[/javascript]
</pre>

So, now my Angular app knows what login status the user has, and can perform the client side routing based on this status.
<h4>Enforcing the routing policy client-side</h4>

<strong>Warning: I want to stress the importance of securing your server-side API once-again. The routing policy we're "enforcing" client-side is <em>very</em> easy to get around using Chrome Developer Tools or Firebug. The technique I'm describing is used as a way of tailoring your views and giving a better user experience, but malicious users can still change their user role and get access to client-side routes that should be restricted to them. This is not a problem as long as any sensitive data is accessed via your server-side API, and the proper authentication/authorization strategy is implemented there.</strong>

Now that I have access to the current user's role and the access level of each route I can actually enforce the policy I've configured.
This functionality is implemented in the <code>Auth</code> service I mentioned earlier, so that I can use it in the other components of my Angular app.

<pre>
[javascript]

angular.module('angular-client-side-auth')
.factory('Auth', function($http, $rootScope, $cookieStore){

    ...

    $rootScope.accessLevels = accessLevels;
    $rootScope.userRoles = userRoles;

    return {
        authorize: function(accessLevel, role) {
            if(role === undefined)
                role = $rootScope.user.role;
            return accessLevel &amp; role;
        },

        isLoggedIn: function(user) {
            if(user === undefined)
                user = $rootScope.user;
            return user.role === userRoles.user || user.role === userRoles.admin;
        },

        register: function(user, success, error) {
            $http.post('/register', user).success(success).error(error);
        },

        login: function(user, success, error) {
            $http.post('/login', user).success(function(user){
                $rootScope.user = user;
                success(user);
            }).error(error);
        },

        logout: function(success, error) {
            $http.post('/logout').success(function(){
                $rootScope.user = {
                    username = '',
                    role = userRoles.public
                };
                success();
            }).error(error);
        },

        accessLevels: accessLevels,
        userRoles: userRoles
    };
});
[/javascript]
</pre>

Now I can inject this service in any other component of my Angular application. For example, to actually enforce my routing policy I need to utilize the <code>authorize()</code> and <code>isLoggedIn()</code> functions in an event handler on $routeChangeStart:

<pre>
[javascript]
$rootScope.$on(&quot;$routeChangeStart&quot;, function (event, next, current) {
    if (!Auth.authorize(next.access)) {
        if(Auth.isLoggedIn()) $location.path('/');
        else                  $location.path('/login');
    }
});
[/javascript]
</pre>

Now, whenever a route is accessed, the proper authorization check will be performed before serving up the view, and a redirect will happen in case the user has insufficient permissions.

One gotcha here is that the session could time out making the client believe the user is logged in when in fact he is declined when communicating with the server resource API. However this can be rectified by using an HTTP interceptor to detect API calls that were denied. Mine is pretty simple, and just redirects to the login page in case of a 401.

<pre>
[javascript]
angular.module('angularAuth', 
    ['angularAuth.filters',
    'angularAuth.services', 
    'angularAuth.directives', 
    'ngCookies'])
.config([
    '$routeProvider', 
    '$locationProvider', 
    '$httpProvider', 
    function ($routeProvider, $locationProvider, $httpProvider) {

    ...

    var interceptor = ['$location', '$q', function($location, $q) {
        function success(response) {
            return response;
        }

        function error(response) {

            if(response.status === 401) {
                $location.path('/login');
                return $q.reject(response);
            }
            else {
                return $q.reject(response);
            }
        }

        return function(promise) {
            return promise.then(success, error);
        }
    }];

    $httpProvider.responseInterceptors.push(interceptor);
});
[/javascript]
</pre>

<h4>Customizing views based on user role</h4>
As you may have noticed, in the <code>Auth</code> service I made the <code>userRoles</code> and <code>accessLevels</code> available to my views by setting them on the <code>$rootScope</code>. This paves the way for a directive I've made which you can use to show/hide elements based on the current user's role. Here's the directive:

<pre>
[javascript]

angular.module('angular-client-side-auth')
.directive('accessLevel', ['$rootScope', 'Auth', function($rootScope, Auth) {
    return {
        restrict: 'A',
        link: function(scope, element, attrs) {
            var prevDisp = element.css('display');
            $rootScope.$watch('user.role', function(role) {
                if(!Auth.authorize(attrs.accessLevel))
                    element.css('display', 'none');
                else
                    element.css('display', prevDisp);
            });
        }
    };
}]);

[/javascript]
</pre>

So, whenever you decorate a tag with the <code>access-level</code> directive, it will check the role of the current user, perform an authorization check using the injected <code>Auth</code>, and then show/hide the element. It also remembers the previous <code>display</code> property of the element in case the user logs out, thus changing her role.

I really want to stress again the point that this scheme exposes all the routing logic and view templates to the client, and can easily be manipulated by the end user. So, you still have to make sure that the calls to the server are properly authenticated and authorized there.

I have made a complete example with all the code available in <strong><a href="https://github.com/fnakstad/angular-client-side-auth">this GitHub repository</a></strong>, which might illustrate this example better than I have been able to in this blogpost.
