module main

import veb
import db.sqlite


pub struct Context {
    veb.Context
pub mut:
    // In the context struct we store data that could be different
    // for each request. Like a User struct or a session id 
    user User
    api_user ApiUser
}

pub struct App {
pub:
    // In the app struct we store data that should be accessible by all endpoints.
    // For example, a database or configuration values.
    api_version     string
    db              sqlite.DB
    port            u16
    hash_algorithm  HashAlgorithm
}

fn main() {
    // App global config
    mut app := &App{
        api_version:    "0.0.0" // Probably want to move this to the v.mod version number
        db:             sqlite.connect('securitysensei.db') or { panic(err) }
        port:           8080
        hash_algorithm: HashAlgorithm.sha256
    }

    // Setup DB tables if not exist.
    sql app.db {
        create table User
        create table ApiUser
    } or { panic(error) }

    // Pass the App and context type and start the web server on port 8080
    veb.run[App, Context](mut app, app.port)
}

// ---------------------------
// -- Sessions and Security --
// ---------------------------

// Permissions defines the permission set for the application. 
// We use RBAC for the best-fit set of permissions. 
enum Permission as u8 {
    read_only   // Read Only
    user        // Read Write
    admin       // Read Write Modify: [admins, users, read_only'ers, API connections]
    owner       // Read Write Modify: [owners, admins, users, read_only'ers, API connections, account data management]
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

// This structure defines how we manage Users and User.sessions in the database. 
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

// Similar to a User object but API_Users are in a many to one relationship with a User. E.g. A user may create more
// than one API key but an API key can have no more than one creator. API users will have to hit an API endpoint for a 
// Session object using their api_key for authentication. Then they use the session object to access the API. 
@[table: 'ApiUsers']
pub struct ApiUser {
pub:
    api_key_id      int         @[primary; unique]
    creator_user_id int
    description     string
    status          UserStatus
    creation        i64         // 2038 fix
    expiration      i64         // if set to 0, never expire. 
    permissions     Permission
    api_key         string
}

// -----------------------
// -- Public Routes --
// -----------------------

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