# avto-lux161

## WARNING

Project was left in the middle of refactoring process,
it most likely in a broken state.
Changes just stored to archive it, it's not planned to work on this project
anymore.

## How to deploy

1. Clone this repo and go to the cloned directory:
  
  ```bash
  $ git clone https://github.com/web-izmerenie/avto-lux161 avto-lux161
  $ cd avto-lux161
  ```
2. Install git-submodules:
  
  ``` bash
  $ git submodule update --init
  ```
  
3. Create Python virtual environment and activate it:
  
  ```bash
  $ pyvenv .venv
  $ source ./.venv/bin/activate
  ```
  
4. Install Python requirements:
  
  ```bash
  $ pip3 install -r requirements.txt
  ```
  
5. Copy [config.yaml.example](./config.yaml.example) to `config.yaml` and
  set in `config.yaml`:
  
  1. `DATABASE` — set correct access data to database.
    According to [this guide](#prepare-new-database):
    
    ```yaml
    DATABASE:
      HOST: 'localhost'
      PORT: ''
      DBNAME: 'avtolux_dbname'
      USER: 'avtolux_user'
      PASS: 'avtolux_password'
      TABLE_NAME_PREFIX: 'avtolux_'
    ```
    
  2. `DEV_SERVER` — if you going to start development server;
  3. `PRODUCTION_SERVER` — if you going to start production server.<br>
    <b>WARNING!:</b> don't set instances more than <b>1</b>,
    cause it isn't supported yet, need some debug for errors;
  4. `DEBUG` — set to <b>1</b> if you wan't more debug info.
  
6. Copy `./files/uploaded/` dir from backup archive to `./files/uploaded/`.
  
  Just for example, doing it by extracting from backup
  (you should be inside root of the project and backup should be placed there too):
  
  ```bash
  $ cd files
  $ tar -xzf ../avtolux_files_backup_20150308050634.tar.gz --strip-components=1 files/uploaded/
  ```
  
  Or if you don't have any backups skip this item and go to the next one.
  
7. Fill database by database dump from backup archive:
  
  If you have started without any backups [read this](#deploy-with-clean-database)
  and skip this item.
  
  ```bash
  $ cat avtolux_db_dump_20150308041213.sql.gz | gunzip | psql -h localhost -d avtolux_dbname -U avtolux_user
  ```
  
  Where `avtolux_db_dump_20150308041213.sql.gz` is database dump,
  `avtolux_user` is user for database access
  and `avtolux_dbname` is a database name;
  
8. Install <b>npm</b> dependencies and build some front-end stuff:
  
  ```bash
  $ npm install
  ```
  
  And build optimized production front-end bundles:
  ```bash
  $ npm run bundle-production
  ```
  
  Or build pretty development bundles and start watcher for development:
  ```bash
  $ npm run bundle-development-client
  $ npm run bundle-development-admin
  ```
  
  It uses [<b>webpack</b>](//webpack.github.io/) for bundling, you can run
  just this project local <b>webpack</b> executable by this command:
  ```bash
  $ npm run webpack
  ```
  See for `scripts` key in [`package.json`](./package.json), also you can call <b>webpack</b>
  with specific arguments through `--`, for example show <b>webpack</b> help:
  ```bash
  $ npm run webpack -- --help
  ```
  
9. Run web-server:
  
  In debug mode:
  ```bash
  $ ./run_development.sh
  ```
  
  Or in production mode:
  ```bash
  $ ./run_production.sh
  ```

## Useful information

### Pull last revision

After pull fresh revision from git don't forget to run:

```bash
$ ./migrate.sh
```

It automatically checks what migrations needed and then apply them, or it
will do nothing if all migrations already applied.

### Deploy with clean database

May be you wan't to know how to create new database and new user
to access this database? Then [read this first](#prepare-new-database).

```bash
$ ./avto-lux/manage.py dbsync
```

And then create new admin user:
```bash
$ ./avto-lux/manage.py create-admin
```
It will create accout with login `admin` and password `admin`.<br>
<b>WARNING!</b> Do not foget to go later to `/adm/` route and change this login/password!

Now you can start development:
```bash
$ ./run_development.sh
```
Or production (doesn't matter):
```bash
$ ./run_production.sh
```
Don't be afraid of 500 error, because we don't have main page yet.

After that you can go to `/adm/#panel/pages` route and create main page
(page with path `/`).

Now it would be good to add some data fields that used on site,
go to route `/adm/#panel/data/add.html` and create this fields
(for `name` field in every level just use any useful human-name
and use number value for `sort`, main key is `symbol key`):
  1. `phones`:
    1. `header` text (multiple)
    2. `footer` text (single)
  2. `email`:
    1. `footer` text (single)
  3. `counters`:
    1. `bottom_counters` multiline text (multiple)
  4. `robots`:
    1. `robots` multiline text (single) with value:

        ```robots
        User-agent: *
        Disallow: /adm/
        Disallow: /static/admin-templates/
        Disallow: /static/ckeditor/
        ```

### Prepare new database

Login as `postgres` user:
```bash
$ sudo su - postgres
```
Then open interactive PostgreSQL terminal:
```bash
$ psql
```
Inside that terminal create new user:
named as `avtolux_user` with password `avtolux_password`:
```sql
create user avtolux_user with password 'avtolux_password' ;
```
After that create new database named as `avtolux_dbname`:
```sql
create database avtolux_dbname ;
```
And give user created before all privileges to this new database:
```sql
grant all on database avtolux_dbname to avtolux_user ;
```
You can check if it's done:
```sql
\l
```
Done!

### How to make backup

#### Database dump

```bash
$ pg_dump -h localhost -d avtolux_dbname -U avtolux_user | gzip > avtolux_db_dump_`date +'%Y%m%d%H%M%S'`.sql.gz
```

Where `avtolux_user` is user for database access
and `avtolux_dbname` is a database name;

#### Uploaded files backup

Inside root of the project:

```bash
$ tar -czvf avtolux_files_backup_`date +'%Y%m%d%H%M%S'`.tar.gz files/uploaded/
```
