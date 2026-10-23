CREATE INDEX `idx_api_token_created_by` ON `api_tokens` (`created_by`);--> statement-breakpoint
CREATE INDEX `idx_deploy_concluded_latest` ON `deployments` (`platform`,`project_name`,`environment`,`created_at`,`id`) WHERE ((build_phase IS NULL OR build_phase NOT IN ('canceled', 'unknown')) AND deploy_phase <> 'unknown' AND NOT (build_phase IN ('building', 'queued') OR deploy_phase = 'deploying') AND NOT (build_phase IS NULL AND deploy_phase = 'none'));--> statement-breakpoint
CREATE INDEX `idx_deploy_inflight_latest` ON `deployments` (`platform`,`project_name`,`environment`,`created_at`,`id`) WHERE ((build_phase IS NULL OR build_phase NOT IN ('canceled', 'unknown')) AND deploy_phase <> 'unknown' AND ((build_phase IN ('building', 'queued') OR deploy_phase = 'deploying') OR (build_phase IS NULL AND deploy_phase = 'none')));--> statement-breakpoint
CREATE INDEX `idx_deploy_project_created` ON `deployments` (`platform`,`project_name`,`created_at`);--> statement-breakpoint
CREATE INDEX `idx_deploy_provider_created` ON `deployments` (`platform`,`provider_project_id`,`created_at`);--> statement-breakpoint
CREATE INDEX `idx_deploy_live_host` ON `deployments` (`live_host`) WHERE live_host is not null;--> statement-breakpoint
CREATE INDEX `idx_device_auth_expires` ON `device_authorizations` (`expires_at`);--> statement-breakpoint
CREATE INDEX `idx_device_auth_token` ON `device_authorizations` (`token_id`);--> statement-breakpoint
CREATE INDEX `idx_device_auth_approved_by` ON `device_authorizations` (`approved_by`);--> statement-breakpoint
CREATE INDEX `idx_error_open_last_seen` ON `errors` (`resolved`,`last_seen`,`issue_key`);--> statement-breakpoint
CREATE INDEX `idx_issue_target_opened` ON `issues` (`target`,`opened_at`);--> statement-breakpoint
CREATE INDEX `idx_issue_target_resolved` ON `issues` (`target`,`resolved_at`);--> statement-breakpoint
CREATE INDEX `idx_session_expires` ON `sessions` (`expires_at`);