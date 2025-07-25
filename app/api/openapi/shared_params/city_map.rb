module Openapi
  module SharedParams
    module CityMap
      COUNTRY_CN_EN_MAP = {
        "中国" => "China",
        "香港" => "Hong Kong",
        "台湾" => "Taiwan",
        "美国" => "United States",
        "英国" => "United Kingdom",
        "法国" => "France",
        "德国" => "Germany",
        "加拿大" => "Canada",
        "澳大利亚" => "Australia",
        "俄罗斯" => "Russia",
        "日本" => "Japan",
        "韩国" => "South Korea",
        "朝鲜" => "North Korea",
        "印度" => "India",
        "巴西" => "Brazil",
        "南非" => "South Africa",
        "新加坡" => "Singapore",
        "马来西亚" => "Malaysia",
        "泰国" => "Thailand",
        "越南" => "Vietnam",
        "菲律宾" => "Philippines",
        "印度尼西亚" => "Indonesia",
        "墨西哥" => "Mexico",
        "阿根廷" => "Argentina",
        "土耳其" => "Turkey",
        "西班牙" => "Spain",
        "意大利" => "Italy",
        "瑞士" => "Switzerland",
        "瑞典" => "Sweden",
        "挪威" => "Norway",
        "芬兰" => "Finland",
        "丹麦" => "Denmark",
        "荷兰" => "The Netherlands",
        "比利时" => "Belgium",
        "奥地利" => "Austria",
        "新西兰" => "New Zealand",
        "波兰" => "Poland",
        "捷克" => "Czech Republic",
        "希腊" => "Greece",
        "乌克兰" => "Ukraine",
        "匈牙利" => "Hungary",
        "爱尔兰" => "Ireland",
        "以色列" => "Israel",
        "阿联酋" => "United Arab Emirates",
        "沙特阿拉伯" => "Saudi Arabia",
        "伊朗" => "Iran",
        "埃及" => "Egypt",
        "尼日利亚" => "Nigeria",
        "肯尼亚" => "Kenya",
        "巴基斯坦" => "Pakistan",
        "孟加拉国" => "Bangladesh",
        "哥伦比亚" => "Colombia",
        "智利" => "Chile",
        "秘鲁" => "Peru",
        "委内瑞拉" => "Venezuela",
        "哈萨克斯坦" => "Kazakhstan",
        "卡塔尔" => "Qatar",
        "科威特" => "Kuwait",
        "伊拉克" => "Iraq",
        "叙利亚" => "Syria",
        "缅甸" => "Myanmar",
        "斯里兰卡" => "Sri Lanka",
        "尼泊尔" => "Nepal",
        "老挝" => "Laos",
        "柬埔寨" => "Cambodia",
        "卢森堡" => "Luxembourg",
        "冰岛" => "Iceland",
        "摩洛哥" => "Morocco",
        "突尼斯" => "Tunisia",
        "阿尔及利亚" => "Algeria",
        "苏丹" => "Sudan",
        "埃塞俄比亚" => "Ethiopia",
        "津巴布韦" => "Zimbabwe",
        "乌干达" => "Uganda",
        "坦桑尼亚" => "Tanzania",
        "刚果（金）" => "Democratic Republic of the Congo",
        "刚果（布）" => "Republic of the Congo",
        "马达加斯加" => "Madagascar"
      }.freeze

      def self.to_en(country_cn)
        return nil if country_cn.nil?
        COUNTRY_CN_EN_MAP[country_cn.strip] || country_cn.strip
      end

      def self.to_cn(country_en)
        return nil if country_en.nil?
        COUNTRY_CN_EN_MAP.invert[country_en.strip] || country_en.strip
      end

    end
  end
end
