# AWSサンプル - AWS LambdaをVPCに配置

## 概要

LambdaをVPCと繋ぎ、プライベートサブネットにあるRDS Proxyを経由してRDSに接続するサンプル。

## 構成

フロントはVue3、バックエンドはSAM（Python）で構成する。
DBはAurora MySQLを使用する。

## ローカル実行

1. Dockerのネットワークの作成
    1. `docker network create vpc-lambda-network`
2. DB環境の構築と起動
    1. `docker-compose up`
3. S3バケットの作成
    1. ローカル用にS3バケットを作成する
4. バックエンドの起動
    1. `cd api`
    2. `sam build --cached`
    3. `sam local start-api --docker-network vpc-lambda-network --parameter-overrides Timeout=10 DBHost=db DBUser=admin DBPassword=admin BackendBucketName=<ローカル用バケット名>`
        1. ファイルを編集した場合は`sam build`を実行する必要がある
        2. IDEなどのファイル監視で、`sam build`が実行されるようにすると少し楽になる
        3. JetBrains製品の場合は、File Watcherで`build.sh`を実行するようにすると自動でビルドが走るようにできる
5. フロントの起動
    1. `cd front`
    2. `npm run dev`

## AWS環境の構築手順

1. Terraform実行
    1. `infra/terra/main.tfvars`を作成し、`infra/terra/variables.tf`の変数を設定する
    2. `cd infra/terra`
    3. `terraform init`
    4. `terraform plan --var-file main.tfvars`
    5. `terraform apply --var-file main.tfvars`
2. 踏み台に入ってDB登録
    1. AWSコンソールからEC2にいき、踏み台EC2のセッションマネージャーで接続する
        1. `sudo su - ec2-user`で`ec2-user`に切り替える（切り替えなくてもできるが切り替えた方がやりやすい）
        2. ※Session Manager プラグインを利用してローカルPCからのログインも可能
    2. mysqlコマンドでDBに接続し、`server/mysql/initdb.d/init.sql`のSQLを実行する
        1. DBのエンドポイントはTerraformの出力結果のRDS Proxyに記載されている
        2. DBのユーザ名とパスワードはTerraformの変数で指定したものを使う
        3. mysql -u <ユーザ名> -p -h <DBのエンドポイント>
3. SAMでAPIのビルド＆デプロイ
    1. `cd api`
    2. `sam build`
    3. `sam deploy --guided --no-confirm-changeset`
        1. `Stack Name`は任意の名前をつける
        2. `AWS Region`はTerraformで作成したリージョンと同じにする
        3. `LambdaSubnet1`はTerraformの出力結果の`private_subnet_app_1_id`に出力された値を設定する
        4. `LambdaSubnet2`はTerraformの出力結果の`private_subnet_app_2_id`に出力された値を設定する
        5. `LambdaRole`はTerraformの出力結果の`vpc_lambda_role_arn`に出力された値を設定する
        6. `LambdaSecurityGroup`はTerraformの出力結果の`vpc_lambda_security_group_id`に出力された値を設定する
        7. `BackendBucketName`はTerraformの出力結果の`backend_bucket_name`に出力された値を設定する
        8. `DBHost`はTerraformの出力結果の`rds_proxy_host`に出力された値を設定する
        9. `DBUser`はTerraformの変数で指定した値を設定する
        10. `DBPassword`はTerraformの変数で指定した値を設定する
        11. 他の入力はデフォルトとする
4. フロントのビルド＆デプロイ
    1. `front/.env.production`を作成し、`VUE_APP_API_URL`にAPIのエンドポイントを設定する
        1. APIのエンドポイントはSAMのデプロイの出力結果の`ProductionApi`に出力された値を設定する
    2. `cd front`
    3. `npm run build`
    4. `aws s3 sync ./dist <バケットURI> --delete`
        1. バケットURIはTerraformの出力結果の`frontend_bucket_uri`に出力された値を設定する

## 動作確認

1. フロントのURLにアクセスし、メッセージを登録する
    1. フロントのURLはTerraformの出力結果の`cloud_front_url`に出力された値を使用し、HTTPSでアクセスする
2. 登録したメッセージがテキストボックスの下に表示されることを確認する
3. 踏み台に入ってDBに接続し、`messages`テーブルに登録されていることを確認する
4. ブラウザをリロードし、テキストボックスの下に登録したメッセージが表示されることを確認する

## リソース削除

1. SAMのスタック削除
    1. `cd api`
    2. `sam delete`
        1. 確認の入力が求められるのですべて`y`を入力する
2. S3のバケットの中身を削除
    1. `aws s3 rm <バケットURI> --recursive`
        1. バケットURIはTerraformの出力結果の`frontend_bucket_s3_uri`に出力された値を設定する
        2. バケットURIはTerraformの出力結果の`backend_bucket_uri`に出力された値を設定する
3. Terraformのリソース削除
    1. `cd infra/terra`
    2. `terraform destroy --var-file main.tfvars`

## TODO

- [ ] Cloud Watch Logsのロググループを作成する
- [ ] シークレットマネージャーからのDB情報の取得（ローカル時は環境変数から取得する）
- [ ] テストコード
- [ ] CI/CD
- [ ] ログ出力
- [ ] ログの集約
- [ ] ログの可視化
- [ ] モニタリング