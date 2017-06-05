# -*- coding: utf-8 -*-

import json
from warnings import warn
from tornado.web import RedirectHandler, URLSpec

from .helpers import query_except_handler, require_auth

from app.mixins.routes import JsonResponseMixin

from app.models.dbconnect import Session, db_inspector
from app.models.usermodels import User
from app.models.pagemodels import StaticPageModel, UrlMapping
from app.models.non_relation_data import NonRelationData
from app.models.catalogmodels import CatalogSectionModel, CatalogItemModel


class AdminMainHandler(JsonResponseMixin):
	
	@require_auth
	def post(self):
		
		action = self.get_argument('action')
		kwrgs = {}
		try:
			kwrgs = json.loads(self.get_argument('args'))
		except:
			kwrgs = {}
		
		actions = {
			'get_pages_list': self.get_pages_list,
			'get_catalog_sections': self.get_catalog_sections,
			'get_catalog_elements': self.get_catalog_elements,
			'get_redirect_list': self.get_redirect_list,
			'get_accounts_list': self.get_accounts_list,
			'get_data_list': self.get_data_list,
			
			'get_fields': self.get_fields,
			'add': self.create, # for add new element/section forms
			'update': self.update, # for editing elements/sections forms
			'delete': self.delete, # for deleting elements/sections
			
			'reorder': self.reorder # custom reordering
		}
		
		if action not in actions.keys():
			return self.json_response({
				'status': 'error',
				'error_code': 'non_existent_action'
			})
		func = actions[action]
		
		return func(**kwrgs)
	
	
	@query_except_handler
	def get_pages_list(self):
		
		session = Session()
		
		try:
			result = session.execute(
				StaticPageModel.get_ordered_list_query().done()
			)
			data = session.query(StaticPageModel).instances(result)
		except Exception as e:
			warn(
				'adm/AdminMainHandler.get_pages_list(): '+
				'cannot get static pages:\n%s' % e
			)
			raise e
		finally:
			session.close()
		
		pages_list = [x.static_list for x in data]
		for idx, page in enumerate(pages_list):
			page['sort'] = idx + 1
		
		return self.json_response({
			'status': 'success',
			'data_list': pages_list
		})
	
	
	## TODO : Optimize and using join ¯\(°_o)/¯
	@query_except_handler
	def get_catalog_sections(self):
		
		session = Session()
		
		try:
			cats = session.query(CatalogSectionModel.id).all()
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.get_catalog_sections(): ' +
				'cannot get catalog sections:\n%s' % e
			)
			raise e
		
		counts = []
		for i in cats:
			try:
				count = (
					session
						.query(CatalogItemModel.id)
						.filter_by(section_id=i[0])
						.all()
				)
			except Exception as e:
				session.close()
				warn(
					'adm/AdminMainHandler.get_catalog_sections(): ' +
					'cannot get catalog items by section id #%s:\n%s' %
					(str(i[0]), e)
				)
				raise e
			counts.append((len(count),))
		
		try:
			data = session.query(
				CatalogSectionModel.title,
				CatalogSectionModel.id,
				CatalogSectionModel.is_active
			).all()
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.get_catalog_sections(): ' +
				'cannot get catalog sections:\n%s' % e
			)
			raise e
		
		session.close()
		return self.json_response({
			'status': 'success',
			'data_list': [
				{
					'is_active': bool(x[1][2]),
					'id': x[1][1],
					'title': x[1][0],
					'count': x[0][0]
				} for x in list(zip(counts, data))
			]
		})
	
	
	@query_except_handler
	def get_catalog_elements(self, id):
		
		session = Session()
		
		try:
			data = session.query(
				CatalogItemModel.id,
				CatalogItemModel.title,
				CatalogItemModel.is_active
			).filter_by(section_id=id).all()
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.get_catalog_elements(): ' +
				'cannot get catalog items by section id #%s:\n%s' %
				(str(id), e)
			)
			raise e
		
		try:
			title = session.query(
				CatalogSectionModel.title
			).filter_by(id=id).one()
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.get_catalog_elements(): ' +
				'cannot get catalog section by id #%s:\n%s' % (str(id), e)
			)
			raise e
		
		session.close()
		
		return self.json_response({
			'status': 'success',
			'section_title': title[0],
			'data_list': [
				{
					'is_active': bool(x.is_active),
					'title': x.title,
					'id': x.id
				} for x in data
			]
		})
	
	
	@query_except_handler
	def get_redirect_list(self):
		
		session = Session()
		
		try:
			data = session.query(UrlMapping).all()
		except Exception as e:
			warn(
				'adm/AdminMainHandler.get_redirect_list(): ' +
				'cannot get data from UrlMapping model:\n%s' % e
			)
			raise e
		finally:
			session.close()
		
		return self.json_response({
			'status': 'success',
			'data_list': [x.item for x in data]
		})
	
	
	@query_except_handler
	def get_accounts_list(self):
		
		session = Session()
		
		try:
			data = session.query(User).all()
		except Exception as e:
			warn(
				'adm/AdminMainHandler.get_accounts_list(): ' +
				'cannot get users:\n%s' % e
			)
			raise e
		finally:
			session.close()
		
		return self.json_response({
			'status': 'success',
			'data_list': [
				{
					'id': x.id,
					'login': x.login,
					'is_active': x.is_active
				} for x in data
			]
		})
	
	
	@query_except_handler
	def get_static_page(self, id):
		
		session = Session()
		
		try:
			data = session.query(StaticPageModel).filter_by(id=id).one()
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.get_static_page(): ' +
				'cannot get static page by id #%s:\n%s' % (str(id), e)
			)
			raise e
		
		session.close()
		
		return self.json_response({
			'status': 'success',
			'data': data.item
		})
	
	
	_section_model_map = {
		'pages': StaticPageModel,
		'redirect': UrlMapping,
		'catalog_section': CatalogSectionModel,
		'catalog_element': CatalogItemModel,
		'data': NonRelationData
	}
	
	_section_model_map_with_accounts = _section_model_map.copy()
	_section_model_map_with_accounts['accounts'] = User
	
	# models that support custom ordering
	_custom_ordering_models = [
		StaticPageModel
	]
	
	_able_to_remove_elements_models = [
		User
	]
	
	
	@query_except_handler
	def create(self, section, **fields_data):
		
		# set as True flags that was checked
		# only checked flags will be received from admin-panel front-end
		fields_data.update({
			key: True for key in fields_data.keys()
			if key.startswith('is_') or key.startswith('has_')
		})
		
		session = Session()
		
		Model = self._section_model_map[section]
		
		if Model in self._custom_ordering_models:
			fields_data['prev_elem'] = Model.extract_prev_elem(
				session.query(Model).instances(
					session.execute(
						Model.get_ordered_list_query().only_last().done()
					)
				)
			)
		
		item = Model(**fields_data)
		
		try:
			session.add(item)
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.create(): ' +
				'cannot create item by "%s" section:\n%s' % (str(section), e)
			)
			raise e
		
		if section == 'redirect':
			
			if not self._validate_redirect(fields_data):
				return self.json_response({
					'status': 'error',
					'error_code': 'incorrect_data'
				})
			
			from app.app import application
			
			application().handlers[0][1][:0] = [
				self._get_redirect_router_item(fields_data)
			]
		
		try:
			session.commit()
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.create(): ' +
				'cannot commit create item by "%s" section:\n%s' %
				(str(section), e)
			)
			raise e
			
		session.close()
		
		return self.json_response({'status': 'success'})
	
	
	@query_except_handler
	def update(self, id, section, **fields_data):
		
		Model = self._section_model_map[section]
		
		fields = db_inspector.get_columns(Model.__tablename__)
		fields_data_keys = fields_data.keys()
		fields_data.update({
			# set as True flags that was checked and as False that wasn't
			# only checked flags will be received from admin-panel front-end
			field['name']: field['name'] in fields_data_keys
			for field in fields
			if field['name'].startswith('is_')
			or field['name'].startswith('has_')
			or field['name'].startswith('inherit_seo_')
		})
		
		session = Session()
		
		try:
			data = session.query(Model).filter_by(id=id)
		except Exception as e:
			session.close()
			warn(
				'adm/AdminMainHandler.update(): ' +
				'cannot update element by "%s" section:\n%s' %
				(str(section), e)
			)
			raise e
		
		# TODO :: Clear shitcode
		if section == 'redirect':
			
			if not self._validate_redirect(fields_data):
				return self.json_response({
					'status': 'error',
					'error_code': 'incorrect_data'
				})
			
			from app.app import application
			hndlr = application().handlers[0][1]
			
			for idx in range(len(hndlr)):
				try:
					if hndlr[idx].__dict__['kwargs']['url'] == data.one().new_url:
						hndlr[idx] = self._get_redirect_router_item(fields_data)
				except KeyError:
					continue
		
		data.update(fields_data)
		
		try:
			session.commit()
		except Exception as e:
			warn(
				'adm/AdminMainHandler.update(): ' +
				'cannot commit update element by "%s" section:\n%s' %
				(str(section), e)
			)
			raise e
		finally:
			session.close()
		
		return self.json_response({'status': 'success'})
	
	
	@query_except_handler
	def delete(self, section, id):
		
		Model = self._section_model_map_with_accounts[section]
		if Model not in self._able_to_remove_elements_models:
			warn(
				'adm/AdminMainHandler.delete(): ' +
				'model "%s" is not able to delete elements' % Model.__name__
			)
			return self.json_response({
				'status': 'error',
				'error_code': 'model_is_not_able_to_delete_elements'
			})
		
		session = Session()
		
		# TODO :: support custom reordering
		try:
			session.query(Model).filter_by(id=id).delete()
			session.commit()
		except Exception as e:
			warn(
				'adm/AdminMainHandler.delete(): ' +
				'cannot delete element by id #%s:\n%s' % (str(id), e)
			)
			return self.json_response({
				'status': 'error',
				'error_code': 'system_fail'
			})
		finally:
			session.close()
		
		return self.json_response({'status': 'success'})
	
	
	@query_except_handler
	def get_data_list(self):
		
		session = Session()
		
		try:
			data = session.query(NonRelationData).all()
		except Exception as e:
			warn(
				'adm/AdminMainHandler.get_data_list(): ' +
				'cannot get non-relation data elements:\n%s' % e
			)
			raise e
		finally:
			session.close()
		
		return self.json_response({
			'status': 'success',
			'data_list': [x.item for x in data]
		})
	
	
	@query_except_handler
	def get_fields(self, section, edit=False, id=None):
		
		session = Session()
		
		Model = self._section_model_map_with_accounts[section]
		
		fields = db_inspector.get_columns(Model.__tablename__)
		
		# TODO :: refactoring
		types_map = {
			'BOOLEAN': 'checkbox',
			'TEXT': 'html',
			'VARCHAR(4096)': 'text',
			'VARCHAR(8192)': 'text',
			'VARCHAR(1024)': 'text',
			'VARCHAR(5000)': 'password',
			'JSON': 'data_fields' if section == 'data' else 'files',
			'INTEGER': 'text'
		}
		fields_list = []
		
		for field in fields:
			try:
				
				# ignore 'id', 'section_id' and stuff
				if 'id' in field['name'] or field['name'] == 'prev_elem':
					continue
				
				field_dict = {
					'name': field['name'],
					'type': types_map[str(field['type'])],
					'default_val': field['default']
				}
				if field_dict['type'] == 'files':
					if field_dict['name'] == 'main_image':
						field_dict['mode'] = 'single'
					else:
						field_dict['mode'] = 'multiple'
				
				fields_list.append(field_dict)
				
			except KeyError:
				continue
		
		values = None
		if edit and id is not None:
			
			try:
				data = session.query(Model).filter_by(id=id).one()
			except Exception as e:
				session.close()
				warn(
					'adm/AdminMainHandler.get_fields(): ' +
					'cannot get fields by "%s" model and id #%s:\n%s' %
					(Model.__name__, id, e)
				)
				raise e
			
			def get_field_type_by_name(name):
				for item in fields_list:
					if item['name'] == name:
						return item['type']
			# extract values from model
			def value_resolver(key, val):
				field_type = get_field_type_by_name(key)
				if field_type == 'files':
					try:
						files = json.loads(val)
						assert type(files) is list
					except:
						files = []
					return json.dumps(files)
				elif field_type == 'checkbox':
					if type(val) is bool:
						return val
					else:
						return False
				else:
					return val
			values = { k: value_resolver(k, v) for k, v in data.item.items() }
			
			if section == 'catalog_element':
				values.update({'section_id': data.section_id})
		
		if section == 'catalog_element':
			try:
				sections = session.query(CatalogSectionModel).all()
			except Exception as e:
				session.close()
				warn(
					'adm/AdminMainHandler.get_fields(): ' +
					'cannot get catalog sections list:\n%s' % e
				)
				raise e
			
			fields_list.append({
				'name': 'section_id',
				'type': 'select',
				'default_val': None,
				'list_values': [
					{ 'title': x.title, 'value': x.id } for x in sections
				]
			})
		
		session.close()
		
		for k in ['create_date', 'last_change', '_sa_instance_state', 'password']:
			try: del values[k]
			except Exception: pass
		
		return self.json_response({
			'status': 'success',
			'fields_list': fields_list,
			'values_list': values
		})
	
	
	@query_except_handler
	def reorder(self, section, target_id, at_id):
		
		# TODO
		# Model =
		self._custom_ordering_models
		
		if target_id == at_id:
			self.json_response({'status': 'success'})
			return
		
		session = Session()
		
		try:
			# TODO :: multiple models
			session.execute(
				StaticPageModel
					.get_reorder_page_query()
					.page(target_id)
					.place_before(at_id)
					.done()
			)
			session.commit()
		except Exception as e:
			warn(
				'adm/AdminMainHandler.reorder(): ' +
				'cannot reorder "%d" at "%d":\n%s' % (target_id, at_id, e)
			)
			raise e
		finally:
			session.close()
		
		self.json_response({'status': 'success'})
	
	
	# helpers
	
	# UrlMapping model
	def _validate_redirect(self, fields_data):
		try:
			fields_data['status'] = int(fields_data['status']) \
				if 'status' in fields_data \
				and bool(fields_data['status']) \
				else 300
			if fields_data['status'] not in [300, 301]:
				raise Exception('---invalid---')
		except:
			return False
		return True
	
	# UrlMapping model
	def _get_redirect_router_item(self, fields_data):
		return URLSpec(
			pattern=fields_data['old_url'] + '$',
			handler=RedirectHandler,
			kwargs={
				'url': fields_data['new_url'],
				'permanent': fields_data['status'] == 301
			},
			name=None
		)
