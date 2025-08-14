module main

import veb
import db.sqlite


pub struct Context {
    veb.Context
}

pub struct App {
pub:
    db              sqlite.DB
    port            u16
}

fn main() {
    mut app := &App{
        db:             sqlite.connect('securitysensei.db') or { panic(err) }
        port:           8080
    }

    sql app.db {
        create table User
        create table ApiUser
    } or { panic(error) }

    veb.run[App, Context](mut app, app.port)
}

enum Permission as u8 {
    read_only
    user
    admin
    owner
}

enum UserStatus as u8 {
    enabled
    disabled
}

enum HashAlgorithm as u8 {
    sha256
}

pub struct PasswordHash {
pub mut:
    algorithm   HashAlgorithm
    hash        string
    salt        string
}

@[table: 'Users']
pub struct User {
pub:
    user_id         int         @[primary; unique; serial]
    status          UserStatus
    name            string
    email           string
    password_hash   PasswordHash
    mfa_token       ?string
    permisisons     Permission
    api_keys        ?[]ApiUser   @[fkey: 'creator_user_id']
}

@[table: 'ApiUsers']
pub struct ApiUser {
pub:
    api_key_id      int         @[primary; unique]
    creator_user_id int
    description     string
    status          UserStatus
    creation        i64
    expiration      i64
    permissions     Permission
    api_key         string
}

@['/api/user_registration'; get; post]
pub fn (app &App) user_registration(mut ctx Context) veb.Result {

	new_user := User {
		status: UserStatus.enabled
		name: 'testu'
		email: 'teste'
		password_hash: PasswordHash{
			algorithm:	HashAlgorithm.sha256
			hash:		'1234'
			salt:		'1234'
		}
		permisisons: Permission.owner
	}

	// Compiler Bug
	user_id := sql app.db {
		insert new_user into User
	} or { panic(error) }

    return ctx.json(new_user)
}