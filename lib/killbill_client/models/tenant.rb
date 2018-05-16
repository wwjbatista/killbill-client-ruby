module KillBillClient
  module Model
    class Tenant < TenantAttributes
      KILLBILL_API_TENANTS_PREFIX = "#{KILLBILL_API_PREFIX}/tenants"

      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_by_id(tenant_id, options = {})
          get "#{KILLBILL_API_TENANTS_PREFIX}/#{tenant_id}",
              {},
              options
        end

        def find_by_api_key(api_key, options = {})
          get "#{KILLBILL_API_TENANTS_PREFIX}/?apiKey=#{api_key}",
              {},
              options
        end

        def get_tenant_plugin_config(plugin_name, options = {})
          get_tenant_key_value(plugin_name, "uploadPluginConfig", "plugin config", options)
        end

        def upload_tenant_plugin_config(plugin_name, plugin_config, user = nil, reason = nil, comment = nil, options = {})
          upload_tenant_key_value(plugin_name, plugin_config, "uploadPluginConfig", "get_tenant_plugin_config", "plugin config", user, reason, comment, options)
        end

        def delete_tenant_plugin_config(plugin_name, user = nil, reason = nil, comment = nil, options = {})
          delete_tenant_key_value(plugin_name, "uploadPluginConfig", "plugin config", user, reason, comment, options)
        end

        def get_tenant_user_key_value(key_name, options = {})
          get_tenant_key_value(key_name, "userKeyValue", "tenant key/value", options)
        end

        def upload_tenant_user_key_value(key_name, key_value, user = nil, reason = nil, comment = nil, options = {})
          upload_tenant_key_value(key_name, key_value, "userKeyValue", "get_tenant_user_key_value", "tenant key/value", user, reason, comment, options)
        end


        def delete_tenant_user_key_value(key_name, user = nil, reason = nil, comment = nil, options = {})
          delete_tenant_key_value(key_name, "userKeyValue", "tenant key/value", user, reason, comment, options)
        end

        def search_tenant_config(key_prefix, options = {})

          require_multi_tenant_options!(options, "Searching for plugin config is only supported in multi-tenant mode")

          uri =  KILLBILL_API_TENANTS_PREFIX + "/uploadPerTenantConfig/" + key_prefix + "/search"
           get uri,
              {},
              {
              }.merge(options),
              KillBillClient::Model::TenantKeyValueAttributes
        end


        def get_tenant_key_value(key_name, key_path, error_id_str, options = {})

          require_multi_tenant_options!(options, "Retrieving a #{error_id_str} is only supported in multi-tenant mode")

          uri =  KILLBILL_API_TENANTS_PREFIX + "/#{key_path}/" + key_name
          get uri,
              {},
              {
              }.merge(options),
              KillBillClient::Model::TenantKeyValueAttributes
        end


        def upload_tenant_key_value(key_name, key_value, key_path, get_method, error_id_str, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a #{error_id_str} is only supported in multi-tenant mode")

          uri =  KILLBILL_API_TENANTS_PREFIX + "/#{key_path}/" + key_name
          post uri,
               key_value,
               {
               },
               {
                   :content_type => 'text/plain',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          send(get_method.to_sym, key_name, options)
        end


        def delete_tenant_key_value(key_name, key_path, error_id_str, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Deleting a #{error_id_str} is only supported in multi-tenant mode")

          uri =  KILLBILL_API_TENANTS_PREFIX + "/#{key_path}/" + key_name
          delete uri,
                 {},
                 {
                 },
                 {
                     :content_type => 'text/plain',
                     :user => user,
                     :reason => reason,
                     :comment => comment,
                 }.merge(options)

        end
      end


      def create(use_global_default=true, user = nil, reason = nil, comment = nil, options = {})

        created_tenant = self.class.post KILLBILL_API_TENANTS_PREFIX,
                                         to_json,
                                         {:useGlobalDefault => use_global_default},
                                         {
                                             :user => user,
                                             :reason => reason,
                                             :comment => comment,
                                         }.merge(options)
        #
        # Specify api_key and api_secret before making the call to retrieve the tenant object
        # otherwise that would fail with a 401
        #
        options[:api_key] = @api_key
        options[:api_secret] = @api_secret
        created_tenant.refresh(options)
      end
    end
  end
end
