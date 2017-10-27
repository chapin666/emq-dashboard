%%--------------------------------------------------------------------
%% Copyright (c) 2015-2017 EMQ Enterprise, Inc. (http://emqtt.io).
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_dashboard_api).

-include("emqx_dashboard.hrl").

-rest_api(#{name   => auth_user,
            method => 'POST',
            path   => "/auth",
            func   => auth,
            descr  => "Authenticate an user"}).

-rest_api(#{name   => create_user,
            method => 'POST',
            path   => "/users/",
            func   => create,
            descr  => "Create an user"}).

-rest_api(#{name   => list_users,
            method => 'GET',
            path   => "/users/",
            func   => list,
            descr  => "List users"}).

-rest_api(#{name   => update_user,
            method => 'PUT',
            path   => "/users/:bin:name",
            func   => update,
            descr  => "Update an user"}).

-rest_api(#{name   => delete_user,
            method => 'DELETE',
            path   => "/users/:bin:name",
            func   => delete,
            descr  => "Delete an user"}).

-rest_api(#{name   => change_pwd,
            method => 'PUT',
            path   => "/change_pwd/:bin:username",
            func   => auth,
            descr  => "Change password for an user"}).

-export([list/2, create/2, update/2, delete/2, auth/2, change_pwd/2]).

-define(EMPTY(V), (V == undefined orelse V == <<>>)).

auth(_Bindings, Params) ->
    Username = proplists:get_value(<<"username">>, Params),
    Password = proplists:get_value(<<"password">>, Params),
    case emqx_dashboard_admin:check(Username, Password) of
        ok -> ok;
        {error, Reason} ->
            {error, #{message => Reason}}
    end.

change_pwd(#{username := Username}, Params) ->
    OldPwd = proplists:get_value(<<"old_pwd">>, Params),
    NewPwd = proplists:get_value(<<"new_pwd">>, Params),
    case emqx_dashboard_admin:change_password(Username, OldPwd, NewPwd) of
        ok -> ok;
        {error, Reason} -> {error, #{message => Reason}}
    end.

create(_Bindings, Params) ->
    Username = proplists:get_value(<<"username">>, Params),
    Password = proplists:get_value(<<"password">>, Params),
    Tags = proplists:get_value(<<"tags">>, Params),
    return(case ?EMPTY(Username) orelse ?EMPTY(Password) of
               true  -> {error, <<"Username or password undefined">>};
               false -> emqx_dashboard_admin:add_user(Username, Password, Tags)
           end).

list(_Bindings, _Params) ->
    {ok, [row(User) || User <- emqx_dashboard_admin:all_users()]}.
 
update(#{name := Username}, Params) ->
    Password = proplists:get_value(<<"password">>, Params),
    Tags = proplists:get_value(<<"tags">>, Params),
    return(if
               ?EMPTY(Password) -> {error, <<"Username or password undefined">>};
               true -> emqx_dashboard_admin:update_user(Username, Password, Tags)
           end).
 
delete(#{name := <<"admin">>}, _Params) ->
    return({error, <<"Cannot delete admin">>});

delete(#{name := Username}, _Params) ->
    return(emqx_dashboard_admin:remove_user(Username)).

row(#mqtt_admin{username = Username, tags = Tags}) ->
    [{username, Username}, {tags, Tags}].

return(ok) -> ok;
return({ok, Data}) -> {ok, Data};
return({error, Reason}) -> {error, #{message => Reason}}.
