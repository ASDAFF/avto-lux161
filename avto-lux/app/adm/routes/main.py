# -*- coding: utf-8 -*-

import os, time
import hashlib
import datetime
from warnings import warn

from .helpers import request_except_handler, require_auth

from app.configparser import config
from app.utils import get_json_localization

from app.mixins.auth import AuthMixin
from app.mixins.routes import JsonResponseMixin

from app.models.dbconnect import Session
from app.models.usermodels import User


class AdminMainRoute(JsonResponseMixin):
	
	def get(self, *args):
		lang = config('LOCALIZATION')['LANG']
		localization = get_json_localization('ADMIN')[lang]
		kwrgs = {
			'page_title': localization['page_title'],
			'lang': lang,
			'local': localization,
			'is_auth': 1 if self.get_secure_cookie('user') else 0,
			'is_debug': 1 if self.application.settings.get('debug') else 0
		}
		return self.render('admin/layout.jade', **kwrgs)


class AuthHandler(AuthMixin, JsonResponseMixin):
	
	def post(self):
		
		if self.get_secure_cookie('user'):
			return self.json_response({
				'status': 'success',
				'username': self.get_secure_cookie('user').decode('utf-8')
			})
		
		session = Session()
		try:
			usr = (
				session
					.query(User)
					.filter_by(login=self.get_argument('user'))
					.one()
			)
		except Exception as e:
			warn('adm/AuthHandler.post(): user not found:\n%s' % e)
			return self.json_response({
				'status': 'error',
				'error_code': 'user_not_found'
			})
		finally:
			session.close()
		
		compared = self.compare_password(
			hpasswd=usr.password,
			password=self.get_argument('pass')
		)
		
		if compared and usr.is_active:
			self.set_secure_cookie('user', usr.login)
			return self.json_response({
				'status': 'success',
				'username': usr.login
			})
		elif not usr.is_active:
			return self.json_response({
				'status': 'error',
				'error_code': 'user_inactive'
			})
		
		return self.json_response({
			'status': 'error',
			'error_code': 'incorrect_password'
		})


class LogoutHandler(JsonResponseMixin):
	def post(self):
		self.clear_all_cookies()
		return self.json_response({'status': 'logout'})


class CreateUser(AuthMixin, JsonResponseMixin):
	
	@require_auth
	def post(self):
		
		login = self.get_argument('login')
		passwd = self.get_argument('password')
		
		session = Session()
		
		try:
			olds = [x[0] for x in session.query(User.login).all()]
		except Exception as e:
			session.close()
			warn('adm/CreateUser.post(): cannot get users logins:\n%s' % e)
			raise e
		
		if login == '':
			return self.json_response({
				'status': 'error',
				'error_code': 'unique_key_exist'
			})
		elif login in olds:
			return self.json_response({
				'status': 'error',
				'error_code': 'incorrect_data'
			})
		
		is_active = True
		try:
			self.get_argument('is_active')
		except:
			is_active = False
		
		usr = User(
			login=login,
			password=self.create_password(passwd),
			last_login=datetime.datetime.utcnow(),
			is_active=is_active
		)
		
		try:
			session.add(usr)
			session.commit()
		except Exception as e:
			warn('adm/CreateUser.post(): cannot add user:\n%s' % e)
			raise e
		finally:
			session.close()
		
		return self.json_response({'status': 'success'})


class UpdateUser(AuthMixin, JsonResponseMixin):
	
	@require_auth
	def post(self):
		
		kwargs = {}
		passwrd = self.get_argument('password')
		login = self.get_argument('login')
		id = self.get_argument('id')
		
		is_active = True
		try:
			self.get_argument('is_active')
		except:
			is_active = False
		
		session = Session()
		try:
			usr = session.query(User).filter_by(id=id).one()
		except Exception as e:
			session.close()
			warn(
				'adm/UpdateUser.post(): cannot get user by #%s id:\n%s' %
				(str(id), e)
			)
			raise e
		
		try:
			olds = [x[0] for x in session.query(User.login).all()]
		except Exception as e:
			session.close()
			warn('adm/UpdateUser.post(): cannot get users logins:\n%s' % e)
			raise e
		
		if login == '':
			return self.json_response({
				'status': 'error',
				'error_code': 'unique_key_exist'
			})
		elif usr.login != login and login in olds:
			return self.json_response({
				'status': 'error',
				'error_code': 'incorrect_data'
			})
		
		kwargs.update({
			'login': login,
			'is_active': is_active
		})
		if passwrd != '':
			kwargs.update({'password': self.create_password(passwrd)})
		
		try:
			session.query(User).filter_by(id=id).update(kwargs)
			session.commit()
		except Exception as e:
			warn(
				'adm/UpdateUser.post(): cannot update user #%s data:\n%s' %
				(str(id), e)
			)
			raise e
		finally:
			session.close()
		
		return self.json_response({'status': 'success'})


class FileUpload(JsonResponseMixin):
	
	_extension_map = {
		'application/octet-stream': '', # without extension
		'image/svg+xml': '.svg',
		'text/plain': '.txt'
	}
	
	@require_auth
	@request_except_handler
	def post(self):
		
		file_path = config('UPLOAD_FILES_PATH')
		hashes = []
		
		for f in self.request.files.items():
			
			_file = f[1][0]
			
			_filename = hashlib.sha512(
				str(time.time()).encode('utf-8')
			).hexdigest()[0:35]
			
			if _file['content_type'] in self._extension_map:
				ext = self._extension_map[_file['content_type']]
			else:
				ext = '.' + _file['content_type'].split('/')[1]
			
			fname = _filename + ext
			
			f = open(os.path.join(file_path, fname), 'wb')
			f.write(_file['body'])
			f.close()
			hashes.append({'name': fname})
		
		return self.json_response({
			'status': 'success',
			'files': hashes
		})
