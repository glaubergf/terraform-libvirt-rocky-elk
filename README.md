---
Projeto: terraform-libvirt-rocky-elk
Descrição: Esse projeto provisiona um servidor Rocky Linux 9 (RHEL) para ser instalado o 
           Elastick Stack (Elasticsearch/Kibana/Logstash/Beats). Em um outro projeto com 
           o ansible (ansible-elk), a automação irá instalar e configurar os produtos do 
           ELK Stack, de alguns pacotes e configurção do sistema.
Autor: Glauber GF (mcnd2)
Data: 2024-04-06
---

# Servidor Elastic Stack com Rocky Linux provisionado com KVM (libvirt)

![Image](https://github.com/glaubergf/terraform-libvirt-rocky-elk/blob/main/images/server_tf-kvm-elk.png)

O **[Elastic Stack](https://www.elastic.co/pt/elastic-stack/)** (_também conhecido como ELK Stack_) é composto pelos seguintes produtos: _Elasticsearch_, _Kibana_, _Beats_ e _Logstash_. Com isso, podemos obter dados de maneira confiável e segura de qualquer fonte, em qualquer formato, depois, fazer buscas, análises e visualizações.

Nesse projeto, será provisionado um servidor (_Máquina Virtual_) do **[Rocky Linux 9](https://rockylinux.org/)** com o **[Terraform](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)** usando o provider **[libvirt](https://libvirt.org/)**.

No momento que o servidor estiver sendo provisionada, será automatizado via **[Ansible](https://docs.ansible.com/ansible/latest/getting_started/index.html)** a instalação e configuração dos produtos do _Elastic Stack_ mencionado acima.

Segue o link para o projeto **[ansible-elk](https://github.com/glaubergf/ansible-elk)** no GitHub.

## O Terraform

Segue alguns aspectos sobre o projeto.

Temos 6 arquivos fundamentais para o projeto com o Terraform, que são:

* **provider.tf** 

Este arquivo de configuração do Terraform especifica a versão do provedor libvirt que será utilizada no projeto. O provedor libvirt é uma ferramenta que permite gerenciar máquinas virtuais usando o KVM (Kernel-based Virtual Machine) e o QEMU, através da API do libvirt. Este arquivo define qual a versão do provedor libvirt deve ser usada, que pode ser encontrada no [**Terraform Registry**](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6). A configuração do provedor é essencial para que o Terraform saiba como interagir com o ambiente de virtualização, permitindo a criação, modificação e destruição de recursos virtuais de forma declarativa.

* **libvirt.tf**

Este arquivo de configuração do Terraform define a infraestrutura para uma máquina virtual (VM) usando o provedor libvirt, que permite provisionar servidores em um host libvirt via Terraform, permitindo a automação e gestão de infraestrutura de forma eficiente e reproduzível.

A configuração inclui:

    Provider libvirt: Define o URI para conectar ao hypervisor libvirt. Neste caso, está configurado para se conectar a um sistema local (qemu:///system) e também inclui um comentário para uma conexão remota via SSH (qemu+ssh://<IP>/system).

    Recursos libvirt_pool e libvirt_volume: Cria um pool de armazenamento chamado "elastic" do tipo "dir" e um volume base "rocky-base" a partir de uma imagem qcow2 especificada pela variável var.rocky_9_qcow2_url. Um volume "rocky-qcow2" é criado com base no volume base, com um tamanho definido pela variável var.vm_vol_size.size.

    Data template_file: Utiliza arquivos de template para configurar os dados do usuário e a configuração de rede para a inicialização na nuvem (cloud-init).

    Recurso libvirt_cloudinit_disk: Cria um disco de inicialização na nuvem com os dados do usuário e configuração de rede renderizados a partir dos templates definidos anteriormente.

    Recurso libvirt_domain: Define uma VM chamada "domain-rocky" com configurações específicas como memória, CPU, e interfaces de rede. A VM utiliza o disco de inicialização na nuvem criado anteriormente e define interfaces de console e gráficos.

    Recursos null_resource: Inclui provisionadores para configurar o swap na VM, copiar arquivos de configuração e executar playbooks do Ansible. Esses recursos são dependentes da criação da máquina virtual e dos provisionadores anteriores.

* **variable.tf**

Este arquivo de configuração do Terraform define uma série de variáveis que são usadas para configurar uma máquina virtual (VM) no ambiente de virtualização libvirt. Essas variáveis são usadas para personalizar a configuração da VM, incluindo detalhes como o sistema operacional, tamanho do disco, memória, CPU, endereços IP e MAC, e scripts de inicialização. 

* **output.tf**

Este arquivo de configuração do Terraform define dois outputs que são úteis para a documentação e utilização posterior do domínio criado com o provedor libvirt.

Os outputs são:

    ip: Este output retorna o endereço IP da primeira interface de rede do domínio domain-rocky. O valor é obtido acessando o primeiro elemento da lista de endereços da primeira interface de rede associada ao domínio. Este output é útil para obter o endereço IP diretamente após a criação do domínio, facilitando a interação com a instância criada.

    url: Este output constrói uma URL baseada no endereço IP da primeira interface de rede do domínio domain-rocky. A URL é formatada como http://<endereço_ip>, permitindo que o usuário acesse facilmente a instância criada através de um navegador ou ferramenta de linha de comando como curl. Este output é particularmente útil para testes rápidos de acesso à instância ou para integração com outras ferramentas que necessitam de uma URL para acessar a instância.

* **config/network_config.yml**

Esse formato de configuração de rede permite que os usuários personalizem as interfaces de rede de suas instâncias atribuindo configurações de sub-rede, rotas de criação de dispositivos virtuais (bonds, bridges, vlans) e configuração de DNS.

A configuração inclui:

    version: Define a versão do formato de configuração de rede. Neste caso, a versão é 2, indicando que o arquivo segue a especificação de configuração de rede versão 2.

    ethernets: Define as configurações de rede para interfaces Ethernet.

    dhcp4: Quando definido como true, indica que a interface deve obter automaticamente um endereço IPv4 através do DHCP. Isso é útil para ambientes dinâmicos onde o endereço IP pode mudar.

    addresses: (comentada) permitiria definir manualmente um endereço IPv4 para a interface, juntamente com a máscara de sub-rede.

    gateway4: (comentada) usado para especificar o gateway padrão para a interface.

    nameservers: (comentada) permite definir servidores DNS para a interface. A seção addresses dentro de nameservers está vazia, indicando que os servidores DNS padrão do sistema operacional serão utilizados.

* **config/cloud_init.yml**

O arquivo de configuração [**cloud-init**](https://cloudinit.readthedocs.io/en/latest/index.html) é a maneira mais simples de realizar algumas tarefas por meio de dados do usuário. Este arquivo é baseado no formato YAML e utiliza a sintaxe do cloud-init, uma ferramenta que permite a inicialização de instâncias de nuvem com configurações específicas, como usuários, pacotes, e configurações de rede em um formato amigável.

    bootcmd: Define comandos que são executados no início do processo de inicialização. Neste caso, adiciona uma entrada ao arquivo /etc/hosts para mapear o endereço IP para gw.homedns.xyz e define o nome do host.

    runcmd: Contém comandos que são executados após a inicialização do sistema.As linhas estão desativadas (comentadas).

    ssh_pwauth: Permite autenticação via senha SSH, o que é útil para acesso inicial.

    disable_root: Define se o acesso como root está desabilitado, neste caso, está configurado como false, permitindo o acesso como root.

    chpasswd: Define as senhas para os usuários. A opção expire está definida como false, o que significa que as senhas não expiram.

    users: Cria um usuário com privilégios de sudo sem necessidade de senha. Define o diretório home do usuário e o shell. Além disso, inclui uma chave SSH autorizada para o usuário, permitindo o acesso sem senha via SSH.

    package_update e package_upgrade: Indicam que os pacotes do sistema devem ser atualizados e atualizados durante a inicialização.

    timezone: Define o fuso horário da instância.

    final_message: Exibe uma mensagem após a inicialização completa do sistema, indicando o tempo de atividade em segundos.

## Executar o Projeto

Para executar o projeto, faça o clone do projeto, em seguida, altere algumas informações nos arquivos de configurações de acordo com seu ambiente e no diretório raiz do mesmo,  execute os comandos **_terraform_** a seguir.

* **init** - *Preparar o diretório de trabalho para outros comandos.*

```
terraform init
```

* **plan** - *Mostrar as alterações exigidas pela configuração atual.*

```
terraform plan
```

* **apply** - *Criar ou atualizar a infraestrutura.*

```
terraform apply
```

* **destroy** - *Destruir a infraestrutura criada anteriormente.*

```
terraform destroy
```

Caso queira executar os comandos *apply* e *destroy* sem digitar **yes** para a confirmação, acrescente nos comandos o parâmetro **--auto-approve**, assim ao executar o comando não pedirá a interação de confirmação. Atenção! Não tem volta, rs!

* **--auto-approve** - *Ignorar a aprovação interativa do plano antes de aplicar.*

```
terraform apply --auto-approve
terraform destroy --auto-approve
```

* **--help** - *Para mais informações de comando do _terraform_, use o '--help'.*

```
terraform --help
```

## Licença

**GNU General Public License** (_Licença Pública Geral GNU_), **GNU GPL** ou simplesmente **GPL**.

[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)

------

Copyright (c) 2024 Glauber GF (mcnd2)

Este programa é um software livre: você pode redistribuí-lo e/ou modificar
sob os termos da GNU General Public License conforme publicada por
a Free Software Foundation, seja a versão 3 da Licença, ou
(à sua escolha) qualquer versão posterior.

Este programa é distribuído na esperança de ser útil,
mas SEM QUALQUER GARANTIA; sem mesmo a garantia implícita de
COMERCIALIZAÇÃO ou ADEQUAÇÃO A UM DETERMINADO FIM. Veja o
GNU General Public License para mais detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU
junto com este programa. Caso contrário, consulte <https://www.gnu.org/licenses/>.

*

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>
