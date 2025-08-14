module main

import veb
import db.sqlite

import crypto.sha256
import rand
import rand.seed

import time


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
    env             Enviroment
    port            u16
    hash_algorithm  HashAlgorithm
    verbose_logging bool            // Verbose logging only available in Development mode
}

fn main() {
    // App global config
    mut app := &App{
        api_version:    "0.0.0" // Probably want to move this to the v.mod version number
        db:             sqlite.connect('securitysensei.db') or { panic(err) }
        env:            Enviroment.development
        port:           8080
        hash_algorithm: HashAlgorithm.sha256
        verbose_logging: true
    }

    // Setup DB tables if not exist.
    sql app.db {
        create table User
        create table ApiUser
    } or {
        if app.env == Enviroment.development {
            panic(err)
        }
        else if app.env == Enviroment.production {
            elogger(err)
        }
    }

    // Pass the App and context type and start the web server on port 8080
    veb.run[App, Context](mut app, app.port)
}


// ----------------
// -- Misc Types --
// ----------------
enum Enviroment as u8 {
    development
    production
}

enum LogSeverity as u8 {
    critical
    high
    medium
    low
    informational
    verbose
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

pub struct RegistrationRequest {
pub:
    username    string
    email       string
    password    string
}

// ----------------------
// -- Helper Functions --
// ----------------------
// Leaving off the pub from the function definition will not expose these functions
// as API endpoints.

fn new_hash_password(password string, algorithm HashAlgorithm) !PasswordHash {
	rand.seed(seed.time_seed_array(2))
	ps := rand.ascii(12)
	combined := password + ps
	if algorithm == HashAlgorithm.sha256 {
		ph := sha256.sum(combined.bytes()).hex()
		return PasswordHash{
			algorithm:	HashAlgorithm.sha256
			hash:		ph
			salt:		ps
		}	
	}
	else {
		return error('No such hash algorithm in new_hash_password')
	}
}

fn verify_password (algorithm HashAlgorithm, password string, salt string, to_compare PasswordHash) bool {
	combined := password + salt
	if algorithm == HashAlgorithm.sha256 {
		return (sha256.sum(combined.bytes()).hex() == to_compare.hash)
	}
	return false
}

fn elogger(error IError) {
    println('${time.now().format_ss_milli()} LOG ERROR "${error}"')
}

fn logger(severity LogSeverity, message string) {
	upper_severity := "${severity}".to_upper()
	println('${time.now().format_ss_milli()} LOG ${upper_severity} "${message}"')
}

// -----------------------
// -- Public Routes --
// -----------------------

@['/api/user_registration'; get; post]
pub fn (app &App) user_registration(mut ctx Context) veb.Result {

	error_message := 'error'

	new_user := User {
		status: UserStatus.enabled
		name: 'testu'
		email: 'teste'
		password_hash: new_hash_password('testp', app.hash_algorithm) or {
				if app.env == Enviroment.development {
					panic(err)
				}
				else if app.env == Enviroment.production {
					elogger(err)
					return ctx.request_error(error_message)
				}
				else {
					panic(err)
				}
			}
		permisisons: Permission.owner
	}

	// Compiler Bug
	user_id := sql app.db {
		insert new_user into User
	} or {
        if app.env == Enviroment.development {
            panic(err)
        }
        else if app.env == Enviroment.production {
            elogger(err)
			return ctx.request_error(error_message)
        }
		else {
			panic(err)
		}
    }

    return ctx.json(new_user)
}