#!/bin/bash


git_login() {
  git config --global user.email "rjzondervan@gmail.com"
  git config --global user.name "rjzondervan"
  git config --global credential.helper store
	export credential="https://$GITHUB_USERNAME:$GITHUB_PASSWORD@github.com"
	echo $credential >> ~/.git-credentials
	cat ~/.git-credentials
	cat /askpass.sh
	export GIT_ASKPASS=/askpass
}

get_repo() {
	local dt=$(date '+%Y%m%d%H%M%S')
	local repo=$1
	local folder=$2
	git clone $repo

	cd $folder

	git checkout -b "dev-bundleRunner-${dt}"


	echo "dev-bundleRunner-${dt}"
}

run_docker() {
	cd $1
	docker-compose up -d --build

	while [ ! -d "./api/vendor" ]; do 
		sleep 60 
	done
	sleep 60
}

bundle_tasks() {
	docker-compose exec -T php composer req conduction/commongroundbundle:^2.*-dev
	docker-compose exec -T php composer req symfony/asset:^5.1 symfony/console:5.1 symfony/dotenv:^5.1 symfony/framework-bundle:^5.1 symfony/property-access:^5.1 symfony/translation:^5.1 symfony/yaml:^5.1 phpdocumentor/reflection-docblock:^5.1
	docker-compose exec -T php composer req --dev phpunit/phpunit:^9.3 phar-io/manifest:^2.0.1 phar-io/version:^3.0.1 phpunit/php-code-coverage:^9 symfony/phpunit-bridge:^5.1 phpspec/prophecy:^1.11.1
	sleep 30

	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/common_ground.yaml ./api/config/packages/
	echo "copied common_ground.yaml"

	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/.bettercodehub.yml ./api
	echo "copied .bettercodehub.yaml"
	
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/api-deployment.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/api-service.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/certificate.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/configmap.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/dependencies-secret.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/ingress.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/_helpers.tpl ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/php-deployment.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/php-service.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/secrets.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/api-deployment.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/api-service.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/certificate.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/dependencies-secret.yaml.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/ingress.yaml ./api/helm/templates
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/helm/php-service.yaml ./api/helm/templates
	echo "copied helm templates"

	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/docker-entrypoint.sh ./api/docker/php
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/default.conf.template ./api/docker/nginx/conf.d
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/Dockerfile ./api
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/Dockerfile-nginx ./api
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/docker-compose.yml .
	echo "copied docker stuff"

  rm ./api/config/bootstrap.php
	cp ./api/vendor/conduction/commongroundbundle/Resources/views/repo/bootstrap.php ./api/config
	echo "copied new bootstrap"

	docker-compose exec -T php bin/console app:documentation:generate
	sleep 5 

#	cp ./api/documentation/readme.md .
#	echo "copied readme.md"
#
#  cp ./api/documentation/helm/readme.md ./api/helm
#	echo "copied readme.md"

	cp ./api/documentation/artifacthub-repo.yaml ./api/helm
	cp ./api/documentation/values.schema.json ./api/helm
	echo "copied helm metadata"

	docker-compose down

	docker-compose up -d
	sleep 60

	docker-compose exec -T php bin/console app:helm:update
	sleep 5

	docker-compose exec -T php bin/console app:publiccode:update

	ln -s ./api/public/schema/publiccode.yaml ./publiccode.yaml
	ln -s ./api/public/schema/openapi.yaml ./openapi.yaml

	docker-compose down

	rm api/helm/templates/varnish-deployment.yaml
	rm api/helm/templates/varnish-service.yaml
	rm api/helm/templates/api-loadbalancer.yaml
	rm api/helm/*.tgz
	docker run -ti alpine/helm:3.2.1 dependency update -v $(pwd)/api/helm:/app
	sed -i 's#\/\*.tgz#.\/\*.tgz#g' ./api/helm/.helmignore

	docker-compose up -d

	sleep 5

	docker-compose down

}

git_update() {
	cd $3
	pwd >> ~/runner.log
	git add --all
	git commit -m 'Readme update (badges + description)'
	git push origin $2

	export GITHUB_TOKEN=$GITHUB_PASSWORD
	gh pr create --fill --repo $1
}

run_update() {
	local branch=$(get_repo $1 $2)
	run_docker $2
	bundle_tasks
	cd ..
	run_docker $2
	git_update $1 $branch $2
	cd ..
}

get_repo_name() {
	local repository=$1
	echo $repository
}

export GIT_ASKPASS=/askpass
git_login

IFS=',' read -r -a REPOSITORIES <<< "$REPOSITORIES"
mkdir runner_repos
cd runner_repos

for repo in "${REPOSITORIES[@]}"
do
	export repository=$(get_repo_name $repo)
	export name=${repository##*/}
	run_update $repo $name
done

cd ..