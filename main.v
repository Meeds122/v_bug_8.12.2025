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

// full error dump

// main.v:50:2: warning: unused variable: `user_id`
//    48 | 
//    49 |     // Compiler Bug
//    50 |     user_id := sql app.db {
//       |     ~~~~~~~
//    51 |         insert new_user into User
//    52 |     } or { panic(error) }
// V panic: table.sym: invalid type (typ=ast.Type(0x0 = 0) idx=0). Compiler bug. This should never happen. Please report the bug using `v bug file.v`.

// v hash: db66120
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:19356: at _v_panic: Backtrace
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:36966: by v__ast__default_table_panic_handler
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:36972: by v__ast__Table_panic
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:37671: by v__ast__Table_sym
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:48976: by v__gen__c__Gen_get_table_name_by_struct_type
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:47532: by v__gen__c__Gen_sql_stmt_line
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:47873: by v__gen__c__Gen_write_orm_insert_with_last_ids
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:47731: by v__gen__c__Gen_write_orm_insert
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:47518: by v__gen__c__Gen_sql_insert_expr
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:30246: by v__gen__c__Gen_expr
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:22810: by v__gen__c__Gen_assign_stmt
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:28625: by v__gen__c__Gen_stmt
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:28393: by v__gen__c__Gen_stmts_with_tmp_var
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:28232: by v__gen__c__Gen_stmts
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:39289: by v__gen__c__Gen_gen_fn_decl
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:38826: by v__gen__c__Gen_fn_decl
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:28607: by v__gen__c__Gen_stmt
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:28393: by v__gen__c__Gen_stmts_with_tmp_var
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:28232: by v__gen__c__Gen_stmts
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:27060: by v__gen__c__Gen_gen_file
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:26997: by v__gen__c__cgen_process_one_file_cb
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:33053: by sync__pool__process_in_thread
// /tmp/v_1000/v2.01K2KG4WJR55YC2BF83TR09150.tmp.c:15843: by sync__pool__process_in_thread_thread_wrapper
// 0x77f08ee9caa4: by ???
// 0x77f08ef29c3c: by ???