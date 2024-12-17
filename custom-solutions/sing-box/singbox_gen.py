import json, subprocess

tempate = {"version": 2, "rules": [{"domain_suffix": [],"ip_cidr": []}]}

domains = []

# Удаляем сабдомены из списков
domains_list = [line.rstrip('\n\r') for line in open('../../main_domains/discord-main-domains-list', 'r') if line]
for domain in domains_list:
    skip = False
    for domain_renew in domains_list:
        if domain.endswith(domain_renew) and domain_renew != domain:
            skip = True
            break
    if skip: continue
    domains.append(domain)

ips = []
ip_main_list = [line.rstrip('\n\r') for line in open('../../main_domains/discord-main-ip-list', 'r') if line]
ip_voice_list = [line.rstrip('\n\r') for line in open('../../voice_domains/discord-voice-ip-list', 'r') if line]
for ip in ip_main_list + ip_voice_list:
    ipcdr = f'{ip}/32'
    if ipcdr in ips: continue
    ips.append(ipcdr)

tempate['rules'][0]['domain_suffix'] = domains
tempate['rules'][0]['ip_cidr'] = ips

out = json.dumps(tempate, indent=2)

open('rules/discord-rules.json','w').write(out)

subprocess.run(f"sing-box rule-set compile rules/discord-rules.json -o rules/discord-rules.srs", shell=True)