module main

import db.sqlite

import crypto.sha256
import rand
import rand.seed

pub struct App {
pub:
    db              sqlite.DB
    hash_algorithm  HashAlgorithm
}

fn main() {
	app := &App {
		db:             sqlite.connect('testdb.db') or { panic(err) }
		hash_algorithm: HashAlgorithm.sha256
	}
	sql app.db {
        create table User
        create table ApiUser
    } or { panic(err) }
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

pub struct RegistrationRequest {
pub:
    username    string
    email       string
    password    string
}

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

pub fn (app &App) user_registration() {

	registration_request := RegistrationRequest {
		username: 'test'
		email: 'test'
		password: 'test'
	}
	
	user_permissions := Permission.owner

	new_user := User {
		status: UserStatus.enabled
		name: registration_request.username
		email: registration_request.email
		password_hash: new_hash_password(registration_request.password, app.hash_algorithm) or { panic(err) }
		permisisons: user_permissions
	}

	// Compiler Bug
	user_id := sql app.db {
		insert new_user into User
	} or { panic(err) }
}