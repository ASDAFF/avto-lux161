# -*- coding: utf-8 -*-

import json
import sys
import warnings
import tornado.template
from tornado.web import HTTPError, MissingArgumentError
from .base import BaseHandler

from app.mixins.routes import (
	ErrorHandlerMixin,
	JsonResponseMixin
)

from app.models.dbconnect import Session
from sqlalchemy import select, func

from app.models.pagemodels import (
	StaticPageModel,
	UrlMapping
)
from app.models.catalogmodels import CatalogItemModel

from app.models.utilmodels import (
	CallModel,
	OrderModel
)
from sqlalchemy.orm.exc import MultipleResultsFound, NoResultFound
from datetime import date, time, datetime
from app.utils import (
	get_json_localization,
	send_mail
)
from app.configparser import config

from .decorators import route_except_handler


class MainRoute(BaseHandler, ErrorHandlerMixin):
	@route_except_handler
	def get(self):
		session = Session()
		try:
			page = session\
				.query(StaticPageModel)\
				.filter_by(alias='/', is_active=True)\
				.one()
		except Exception as e:
			warnings.warn(
				'MainRoute.get(): cannot get main page from database' + \
				'\nException: %s' % e
			)
			raise e
		finally:
			session.close()
		menu = self.getmenu(page_alias='/')
		data = page.to_frontend
		data.update({
			'is_catalog': False,
			'is_catalog_item': False,
			'menu': menu,
			'is_debug': config('DEBUG')
		})
		data.update(self.get_nonrel_handlers())
		data.update(self.get_helpers())
		return self.render('client/content-page.jade', **data)
	
	def head(self):
		return self.get()


class StaticPageRoute(BaseHandler, ErrorHandlerMixin):
	@route_except_handler
	def get(self, alias, suffix):
		session = Session()
		alias = '/' + alias + suffix
		try:
			page = session\
				.query(StaticPageModel)\
				.filter_by(alias=alias, is_active=True)\
				.one()
		except Exception as e:
			warnings.warn(
				"StaticPageRoute.get(): cannot get static page or " + \
				"page is not active by '%s' alias" % str(alias) + \
				'\nException: %s' % e
			)
			raise e
		finally:
			session.close()
		menu = self.getmenu(page_alias=alias)
		data = page.to_frontend
		data.update({
			'is_catalog': False,
			'is_catalog_item': False,
			'menu': menu,
			'is_debug': config('DEBUG')
		})
		data.update(self.get_nonrel_handlers())
		data.update(self.get_helpers())
		return self.render('client/content-page.jade', **data)
	
	def head(self, alias, suffix):
		return self.get(alias, suffix)


class FormsHandler(JsonResponseMixin):
	def post(self):
		is_ajax = False
		lang = config('LOCALIZATION')['LANG']
		localization = get_json_localization('CLIENT')[lang]['forms']
		actions = {
			'call' : {
				'fn': self.save_call,
			},
			'order' : {
				'fn': self.save_order,
			}
		}
		
		try:
			is_ajax = self.get_argument('ajax')
		except MissingArgumentError:
			pass
		
		args = dict([ x.split('=') for x
			in str(self.request.body).split('&')
				if 'action' not in x ])
		for key in args:
			args[key] = self.get_argument(key)
		
		action = self.get_argument('action')
		
		if action not in actions.keys():
			if is_ajax:
				self.set_status(400)
				return self.json_response({'status': 'unknown_form'})
			return self.write("Lol, request isn't correct")
		
		p_title = localization['response_page'][action]
		fn = actions[action]['fn']
		
		errors = self.validate_fields(args)
		if len(errors) == 0:
			try:
				fn(args)
			except Exception as e:
				warnings.warn(
					"FormsHandler.post(): post form data error" + \
					'\nException: %s' % e
				)
				self.set_status(500)
				return self.json_response({'status': 'system_fail'})\
					if is_ajax\
					else self.write('Internal server Error')
			
			if is_ajax:
				return self.json_response({'status': 'success'})
			
			kwrgs = self.set_kwargs(
				success_msg_list=['success'], # TODO :: messages!
				title=p_title)
			return self.render('client/content-page.jade', **kwargs)
		
		else:
			if is_ajax:
				self.set_status(400)
				self.json_response({
					'status': 'error',
					'error_fields': { x: 'required' for x in errors }
				})
			else:
				err_list = [localization['err']['required_page'].format(localization['fields'][x]) \
					for x in errors ]
				kwrgs = self.set_kwargs(
					error_msg_list=err_list,
					title=p_title)
				self.render('client/content-page.jade', **kwrgs)
	
	
	def set_kwargs(self, success_msg_list=[], error_msg_list=[], title=''):
		return {
			'success_msg_list': success_msg_list,
			'error_msg_list': error_msg_list
		}
	
	def validate_fields(self, fields):
		err_stack = []
		all_required_fields = ['name', 'phone', 'callback']
		
		for key in fields:
			if key in all_required_fields and fields[key] is '':
				err_stack.append(key)
		
		if self.get_argument('action') == 'order':
			dt = fields['date'].split('.') if fields['date'].strip() != '' else None
			if dt is not None and len(dt) != 3:
				warnings.warn(
					'FormsHandler.validate_fields(): date digits count ' + \
					'should equal 3 (d.m.Y), hacking attempt?'
				)
				raise Exception('Incorrect date from client-side')
		
		return err_stack
	
	
	def save_call(self, d):
		call = CallModel(
			name = d['name'],
			phone = d['phone'],
			date = datetime.utcnow()
		)
		session = Session()
		try:
			session.add(call)
			session.commit()
		except Exception as e:
			warnings.warn(
				'FormsHandler.save_call(): cannot save call to DB' + \
				'\nException: %s' % e
			)
			raise e
		finally:
			session.close()
		
		send_mail(
			msg='<h1>Заказ звонка</h1>' +
				'<dl><dt>Имя:</dt><dd>%s</dd>' % d['name'] +
				'<dt>Телефон:</dt><dd>%s</dd></dl>' % d['phone'],
			theme='АвтоЛюкс: заказ звонка'
		)
	
	
	def save_order(self, d):
		
		dt = d['date'].split('.') if d['date'].strip() != '' else None
		hours = d['hours'] if d['hours'].strip() != '' else None
		minutes = d['minutes'] if d['minutes'].strip() != '' else None
		
		session = Session()
		try:
			item = session.query(CatalogItemModel).filter_by(id=d['id']).one()
		except Exception as e:
			warnings.warn(
				'FormsHandler.save_order(): cannot get catalog item by id' + \
				'\nException: %s' % e
			)
			raise e
		finally:
			session.close()
		full_date = datetime.combine(
			date(int(dt[2]), int(dt[1]), int(dt[0])),
			time(int(hours), int(minutes))
		) if dt is not None and hours is not None and minutes is not None else None
		order = OrderModel(
			name=d['name'],
			callback=d['callback'],
			date=full_date,
			item_id=item.id
		)
		
		session = Session()
		try:
			session.add(order)
			session.commit()
		except Exception as e:
			warnings.warn(
				'FormsHandler.save_order(): cannot save order to DB' + \
				'\nException: %s' % e
			)
			raise e
		finally:
			session.close()
		send_mail(
			msg='<h1>Заказ "%s"</h1>' % item.title +
				'<dl><dt>Имя:</dt><dd>%s</dd>' % d['name'] +
				'<dt>Контакты:</dt><dd>%s</dd>' % d['callback'] +
				'<dt>Дата заказа:</dt><dd>%s</dd></dl>' % (
					full_date.strftime('%d.%m.%Y %H:%M')
						if full_date is not None
						else 'Не указана'
				),
			theme='АвтоЛюкс: заказ "%s"' % item.title
		)
