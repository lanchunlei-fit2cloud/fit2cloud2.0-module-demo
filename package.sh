ARGS=`getopt -o ha:s: --long help,accesskey:,secretkey: -- "$@"`
if test $? != 0  ; then echo "Please input oss accesskey & secretkey..." >&2 ; exit 1 ; fi
eval set -- "$ARGS"
while true;do
	case "$1" in
	-a|--accesskey)
		echo "-a | --accesskey"
		ak=$2
		shift 2
	;;
	-s|--secretkey)
		echo "-s | --accesskey"
		sk=$2
		shift 2
	;;
	-h|--help)
		echo "-h | --help"
		shift
	;;
	--)
		shift
		break
	;;
	*)
		echo "未知的属性:{$1}"
		exit 1
	;;
	esac
done

rm -rf *.tar.gz *.md5 extension

image_url=`grep "docker push" build.sh | head -n 1 | awk -F" " '{print $3}'`
image_name=`echo $image_url | awk -F"/" '{ print $3 }'`
image=`echo $image_name | awk -F":" '{ print $1 }'`
version=`awk '/<version>[^<]+<\/version>/{gsub(/<version>|<\/version>/,"",$1);print $1;exit;}' pom.xml`
new_version=${version%.*}
build_version=V$new_version.$BUILD_NUMBER

mkdir extension
echo "拉取镜像 : "$image_url
docker pull $image_url

echo "准备扩展模块安装包"
docker save -o extension/${image_name}.tar ${image_url}
sed -i '/^version=/d' service.inf
echo "version=$build_version" >> service.inf
\cp service.inf extension/
\cp service.ico extension/
\cp docker-compose.yml extension/

echo "制作扩展模块安装包"
install_file=$image-$build_version.tar.gz
tar zcvf $install_file extension

md5_file_name=${install_file}.md5
md5sum ${install_file} | awk -F" " '{print "md5: "$1}' > ${md5_file_name}

echo "上传扩展模块安装包"
java -jar /root/uploadToOss.jar $ak $sk fit2cloud2-offline-installer extensions/$image/$build_version/$install_file $install_file
java -jar /root/uploadToOss.jar $ak $sk fit2cloud2-offline-installer extensions/$image/$build_version/service.inf service.inf
java -jar /root/uploadToOss.jar $ak $sk fit2cloud2-offline-installer extensions/$image/$build_version/service.ico service.ico
java -jar /root/uploadToOss.jar $ak $sk fit2cloud2-offline-installer extensions/$image/$build_version/$md5_file_name $md5_file_name

rm -rf $install_file $md5_file_name extension
