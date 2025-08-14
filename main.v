module main

import veb
import db.sqlite


pub struct Context {
    veb.Context
}

pub struct App {
pub:
    db              sqlite.DB
}

fn main() {
    mut app := &App{
        db: sqlite.connect('test.db') or { panic(err) }
    }

    sql app.db {
        create table User
    } or { panic(error) }

    veb.run[App, Context](mut app, 8080)
}

pub struct PasswordHash {
pub mut:
    algorithm   string
}

@[table: 'Users']
pub struct User {
pub:
    user_id         int         @[primary; unique; serial]
    password_hash   PasswordHash
}

@['/api/user_registration'; get; post]
pub fn (app &App) user_registration(mut ctx Context) veb.Result {

	new_user := User {
		password_hash: PasswordHash{
			algorithm:	'sha'
		}
	}

	// Compiler Bug
	user_id := sql app.db {
		insert new_user into User
	} or { panic(error) }

    return ctx.json(new_user)
}

// So far, in my experimentation, the bug only shows up when the veb framework is involved, and insert has nested objects. 
// - changing PasswordHash to a string (removing the nesting) does not recreate the bug. 
// - removing the veb handlers does not recreate the bug